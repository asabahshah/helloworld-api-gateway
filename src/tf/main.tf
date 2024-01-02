# Create VPC
resource "aws_vpc" "lambda_vpc" {
  cidr_block = var.cidr_block
}

# Create Subnets
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.lambda_vpc.id
  cidr_block        = ""
  availability_zone = "eu-west-2a"
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.lambda_vpc.id
  cidr_block        = ""
  availability_zone = "eu-west-2b"
}

# Create Security Group
resource "aws_security_group" "ingress_vpc_sg" {
  name        = "vpc_sg"
  description = "Security group restricting rest api ingress"
  vpc_id      = aws_vpc.lambda_vpc.id
}

resource "aws_security_group_rule" "sg-rule" {
  security_group_id = aws_security_group.ingress_vpc_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ""
}


# Hello world lambda 
resource "aws_lambda_function" "hello_world_lmb" {
  filename      = "../../hello_world.zip"
  function_name = "helloworldlambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello_world.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10
  memory_size   = 128
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  source_code_hash = filebase64sha256("../../hello_world.zip")
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      },
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })

  inline_policy {
    name = "lambda_policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "lambda:InvokeFunction"
          Effect   = "Allow"
          Resource = "arn:aws:lambda:eu-west-2:853889336394:function:helloworldlambda"
        }
      ]
    })
  }
}


# REST API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "hello_api_gateway"
  description = "API Gateway for Hello World"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "hello"
}

# API Gateway method
resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create API Gateway integration with Lambda function
resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.api_gateway_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_world_lmb.invoke_arn
}



# Create API Gateway method response
resource "aws_api_gateway_method_response" "api_gateway_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.api_gateway_resource.id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  status_code = "200"


}
# Create API Gateway integration response
resource "aws_api_gateway_integration_response" "api_gateway_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.api_gateway_resource.id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  status_code = "200"
}

# Create API Gateway deployment
resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
  depends_on = ["aws_api_gateway_method.api_gateway_method", "aws_api_gateway_integration.api_gateway_integration"]
}

# Stitch together Lambda and API Gateway trigger
resource "aws_lambda_permission" "api_gateway_trigger" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world_lmb.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_deployment.api_gateway_deployment.execution_arn
}
