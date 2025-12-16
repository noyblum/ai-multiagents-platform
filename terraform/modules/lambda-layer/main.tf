resource "null_resource" "build_layer" {
  triggers = {
    requirements = filemd5(var.requirements_file)
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/layer/python
      docker run --platform linux/amd64 --rm \
        -v "${abspath(var.requirements_file)}:/requirements.txt:ro" \
        -v "${abspath(path.module)}/layer/python:/var/task" \
        public.ecr.aws/sam/build-python3.12 \
        pip install -r /requirements.txt -t /var/task
    EOT
  }
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/${var.layer_name}.zip"
  
  depends_on = [null_resource.build_layer]
}

resource "aws_lambda_layer_version" "this" {
  filename            = data.archive_file.layer_zip.output_path
  layer_name          = var.layer_name
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
  compatible_runtimes = ["python3.12"]

  depends_on = [data.archive_file.layer_zip]
}
