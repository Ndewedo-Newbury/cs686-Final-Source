output "function_name" {
  value = aws_lambda_function.test_runner.function_name
}

output "function_arn" {
  value = aws_lambda_function.test_runner.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.test_runner.repository_url
}
