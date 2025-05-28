playbook := "playbook.yml"

default:
    @just --list --unsorted | grep -v "  default"

fmt:
    @just terraform/fmt
    @just ansible/fmt

check:
    @just terraform/check
    @just ansible/check

dry:
    @just terraform/dry
    @just ansible/dry

tdeploy:
    @just terraform/deploy

adeploy: tdeploy
    @just ansible/deploy

deploy: tdeploy adeploy

destroy:
    @just terraform/destroy
    @just ansible/destroy
