# Lambda Layer for common dependencies (boto3, PyJWT)
# Uses chat's requirements.txt as reference
module "common_layer" {
  source = "./modules/lambda-layer"

  layer_name        = "${var.project_name}-common-${var.environment}"
  requirements_file = "${path.module}/functions/chat/requirements.txt"
}

# Lambda Layer for auth dependencies (boto3, bcrypt, PyJWT)
# Uses login's requirements.txt
module "auth_layer" {
  source = "./modules/lambda-layer"

  layer_name        = "${var.project_name}-auth-${var.environment}"
  requirements_file = "${path.module}/functions/login/requirements.txt"
}
