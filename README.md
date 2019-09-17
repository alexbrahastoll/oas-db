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
  - Presence of sensitive information in the query string

## Adding / editing samples

Before adding or editing a sample, please run it through the IBM OpenAPI Validator
(using the configurations present in the `.validaterc` in the root of this project)
and make sure it passes the linter.

If the linter is installed, run the following command in the root of this project:

```
lint-openapi a-sample-name.yml
```
