output "function_name" {
  value = length(aws_lambda_function.test_runner) > 0 ? aws_lambda_function.test_runner[0].function_name : ""
}

output "function_arn" {
  value = length(aws_lambda_function.test_runner) > 0 ? aws_lambda_function.test_runner[0].arn : ""
}

output "ecr_repository_url" {
  value = aws_ecr_repository.test_runner.repository_url
}
