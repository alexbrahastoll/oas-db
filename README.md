# OAS DB

OAS DB is an effort to build a repository of synthetic (but realistic) OpenAPI specification samples with known antipatterns. Each specification is also accompanied by an annotation file in the JSON format. The annotation file lists all antipatterns found in the related specification, describing which part of the spec is responsible for which offense.

The annotation files follow a clearly defined schema (soon to be added to this repository) and therefore are a convenient tool for researchers to programatically verify the performance of their tools when run against OAS DB.

OAS DB is a work in progress and although it currently has only a few OpenAPI samples, new one are being added every week or so.

If you are interested in the project, we recommend you also read [the paper we presented at SATToSE 2020](http://sattose.org/).

## Repository structure

OAS DB is composed of the following directories and files:

### samples

This directory contains all OpenAPI samples.

### annotations

This directory contains all annotation files. Each annotation file describes all the antipatterns present in the corresponding OpenAPI sample.

Example: `annotations/orders.json` lists all the antipatterns to be found in `samples/orders.json`

### meta

This directory contains files that supplement and enhance OAS DB itself.

## List of available samples

_To check the antipatterns present in each specification, refer to the corresponding annotation file._

**ecommerce.yml (and ecommerce.json annotation)**

Describes an ecommerce API.

**payment.yml (and payment.json annotation)**

Describes a payments provider API.

## Adding / editing samples

> IMPORTANT: We are not accepting contributions at the moment. This section is a work in progress for the process we are envisioning after contributions are open to the research community at large.

Before adding or editing a sample, please run it through the IBM OpenAPI Validator
(using the configurations present in the `.validaterc` in the root of this project)
and make sure it passes the linter.

If the linter is installed, run the following command in the root of this project:

```
lint-openapi a-sample-name.yml
```
