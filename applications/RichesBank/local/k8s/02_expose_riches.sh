#!/bin/bash

kubectl expose deployment riches --type=NodePort --port 8080 --name=riches-service --dry-run -o yaml
