locals {
  name   = "markarian-postgresql"
  region = "us-east-2a"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

################################################################################
# RDS Module
################################################################################

module "db" {
    source  = "terraform-aws-modules/rds/aws"
    identifier = local.name

    # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
    engine               = "postgres"
    engine_version       = "12.4"
    family               = "postgres12" # DB parameter group
    major_engine_version = "12"         # DB option group
    instance_class       = "db.t3.medium"

    allocated_storage     = 20
    max_allocated_storage = 100
    storage_encrypted     = false

    # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
    # "Error creating DB Instance: InvalidParameterValue: MasterUsername
    # user cannot be used as it is a reserved word used by the engine"
    name     = "markarian_db"
    username = "markarian"
    password = "vS9+cL1(nY0.dF3<"
    port     = 5432

    multi_az               = true
    subnet_ids             = [element(aws_subnet.private_subnet.*.id, 1 ), element(aws_subnet.private_subnet.*.id, 2 )]
    vpc_security_group_ids = [aws_security_group.allow_web.id]

    maintenance_window              = "Mon:00:00-Mon:03:00"
    backup_window                   = "03:00-06:00"
    enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

    backup_retention_period = 0
    skip_final_snapshot     = true
    deletion_protection     = false

    performance_insights_enabled          = true
    performance_insights_retention_period = 7
    create_monitoring_role                = true
    monitoring_interval                   = 60

    parameters = [
    {
        name  = "autovacuum"
        value = 1
    },
    {
        name  = "client_encoding"
        value = "utf8"
    }
    ]

    tags = local.tags
    db_option_group_tags = {
    "Sensitive" = "low"
    }
    db_parameter_group_tags = {
    "Sensitive" = "low"
    }
    db_subnet_group_tags = {
    "Sensitive" = "high"
    }
    # publicly_accessible = true
}