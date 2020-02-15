# OAS DB

OAS DB is an effort to build a repository of OpenAPI specification samples with
known antipatterns. Each specification is also accompanied by an annotation file
in the JSON format. The annotation file lists all antipatterns found in the related
specification, describing which part of the spec is responsible for which offense.
Since the annotation files follow a clearly defined schema (soon to be added to this
repository), they are a convenient tool for researchers to programatically verify the performance of
their tools when run against OAS DB.

This repository is still in its very early stages.

## List of available samples

**ecommerce.yml (and ecommerce.json annotation)**

A sample describing a fictional ecommerce API. This sample presents the following
antipatterns:
  - Lack of hypermedia support
  - Sequential integers as resource ID
  - Inappropriate HTTP method
  - Deep path
  - Sensitive information in the path or in the query string

## Adding / editing samples

Before adding or editing a sample, please run it through the IBM OpenAPI Validator
(using the configurations present in the `.validaterc` in the root of this project)
and make sure it passes the linter.

If the linter is installed, run the following command in the root of this project:

```
lint-openapi a-sample-name.yml
```
