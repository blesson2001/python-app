terraform {
  required_providers {
    #Setting the AWS provides and the version
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"



    }
  }
  #Setting up the required terraform version
  required_version = ">= 0.14.9"

}

#Setting up the aws region we want to use.


provider "aws" {
  profile = "default"
  region  = "us-east-1"
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "aws_s3_bucket" "qa-bucket" {
  bucket = "qa-blesson-jacob-platform-challenge"
  acl    = "private"
  tags = {
    Name        = "Qa bucket"
    Environment = "Dev"
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 1
    }
  }
}



resource "aws_s3_bucket" "stage-bucket" {
  bucket = "staging-blesson-jacob-platform-challenge"
  acl    = "private"
  tags = {
    Name        = "stage bucket"
    Environment = "Dev"
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 1
    }
  }
}







resource "kubernetes_namespace" "qa" {
  metadata {
    name = "qa"
  }
}
resource "kubernetes_namespace" "stage" {
  metadata {
    name = "stage"
  }
}


resource "kubernetes_storage_class" "local" {
  metadata {
    name = "local-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_persistent_volume" "qa-pv" {
  metadata {
    name = "qa-pv"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      host_path {
        path = "/qa/data"
        type = "Directory"
      }
    }
  }
}
resource "kubernetes_persistent_volume" "stage-pv" {
  metadata {
    name = "stage-pv"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      host_path {
        path = "/stage/data"
        type = "Directory"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "qa-claim" {
  metadata {
    name      = "qa-claim"
    namespace = "qa"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.qa-pv.metadata.0.name
  }
}
resource "kubernetes_persistent_volume_claim" "stage-claim" {
  metadata {
    name      = "stage-claim"
    namespace = "stage"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.stage-pv.metadata.0.name
  }
}

resource "kubernetes_cron_job_v1" "pythonappcron" {
  metadata {
    name = "pythonappcron-qa"
    annotations = {
      "iam.amazonaws.com/role" : "AdminAccess"
    }
    namespace = "qa"
    }
  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 5  
    schedule                      = "* * * * *"
    job_template {
      metadata{
        name = "python-app-job-templete"
      }
      spec {
        template {
          metadata{
            name = "python-app-templete"
          }
          spec {
            container {
              name    = "python-cron-app"
              image   = "blesson2001/python-renew:latest"
              image_pull_policy = "IfNotPresent"
              volume_mount {
                name = "www-persistent-storage"
                mount_path = "/app"
              }
              }
            volume  {
              name = "www-persistent-storage"
              persistent_volume_claim {
                claim_name = "qa-claim"
              }
            }
            restart_policy = "Never"
            }
          }
        }
      }
    }
  }





resource "kubernetes_cron_job_v1" "pythonappcronstage" {
  metadata {
    name = "pythonappcronstage"
    annotations = {
      "iam.amazonaws.com/role" : "AdminAccess"
    }
    namespace = "stage"
    }
  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    schedule                      = "* * * * *"
    job_template {
      metadata{
        name = "python-app-job-templete"
      }
      spec {
        template {
          metadata{
            name = "python-app-templete"
          }
          spec {
            container {
              name    = "python-cron-app"
              image   = "blesson2001/python-renew:latest"
              image_pull_policy = "IfNotPresent"
              volume_mount {
                name = "www-persistent-storage-stage"
                mount_path = "/app"
              }
              }
            volume {
              name = "www-persistent-storage-stage"
              persistent_volume_claim {
                claim_name = "stage-claim"
              }
            }
             restart_policy = "Never"
            }
          }
        }
      }
    }
  }

