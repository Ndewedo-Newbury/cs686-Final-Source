locals {
  create_roles     = var.lab_role_arn == ""
  cluster_role_arn = var.lab_role_arn != "" ? var.lab_role_arn : aws_iam_role.cluster[0].arn
  node_role_arn    = var.lab_role_arn != "" ? var.lab_role_arn : aws_iam_role.node_group[0].arn
}

resource "aws_iam_role" "cluster" {
  count = local.create_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "node_group" {
  count = local.create_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "nodes" {
  name_prefix = "${var.project_name}-${var.environment}-nodes-"

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  tag_specifications {
    resource_type = "instance"
    tags = { Environment = var.environment }
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.node_instance_type]

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_iam_role_policy_attachment.node_ssm_policy,
  ]

  tags = {
    Environment = var.environment
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count           = local.create_roles ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
