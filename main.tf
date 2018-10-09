variable "api_id" {}
variable "resource_id" {}
variable "method" {}
variable "path" {}
variable "needsKey" {
  default = false
}
variable "lambda" {
  type = "map"
}
variable "stage" {}
variable "main_resource" {}

resource "aws_api_gateway_method" "endpoint-method" {
  rest_api_id   = "${var.api_id}"
  resource_id   = "${var.resource_id}"
  http_method   = "${var.method}"
  authorization = "NONE"
  api_key_required = "${var.needsKey}"
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id   = "${var.api_id}"
  resource_id   = "${var.resource_id}"
  http_method   = "${aws_api_gateway_method.endpoint-method.http_method}"
  status_code   = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = ["aws_api_gateway_method.endpoint-method"]
}

resource "aws_api_gateway_integration" "endpoint-integration" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_method.endpoint-method.resource_id}"
  http_method = "${aws_api_gateway_method.endpoint-method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${var.lambda["invoke_arn"]}"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    "aws_api_gateway_integration.endpoint-integration"
  ]

  rest_api_id = "${var.api_id}"
  stage_name  = "${var.stage}"
}

resource "aws_lambda_permission" "lambda-method-auth" {
  statement_id  = "AllowAPIGatewayInvoke-${aws_api_gateway_integration.endpoint-integration.http_method}"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda["function_name"]}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${var.main_resource}/*/${aws_api_gateway_integration.endpoint-integration.http_method}${var.path}"
}

output "url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}
