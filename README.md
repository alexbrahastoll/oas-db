# OAS DB

OAS DB is an effort to build a repository of OpenAPI specification samples with
known antipatterns.

This database of specs is going to consist of two separate sets of specifications,
both containing samples presenting the same set of good practices violations. This
design is going to allow researchers to use one of the sets for development of
models / tools and the other one for validation.

This repository is still in its very early stages.

## Development samples

**ecommerce.yml**

A sample describing a fictional ecommerce API. This sample includes the following
antipatterns:
  - Usage of sequential integer IDs instead of UUIDs
  - Deep paths
