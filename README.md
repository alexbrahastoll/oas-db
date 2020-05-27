# OAS DB

OAS DB is a proof of concept of a repository of synthetic but realistic OpenAPI specification samples with
known antipatterns.

The purpose of OAS DB is to eventually become a large repository of samples to help researchers developing tools and techniques leveraging OpenAPI specifications.

Since OAS DB (in its current incarnation) is just a proof of concept, it currently has only a few OpenAPI samples.

## Available samples

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
