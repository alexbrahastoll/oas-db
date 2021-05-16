# OAS DB

OAS DB (OpenAPI Specifications Database) aims to provide researchers and industry practitioners a complete solution to streamline the validation of new OpenAPI related techniques and tools. From a small file containing basic information about an API, it is able to generate a complete OpenAPI specification (with the four basic CRUD operations), a mock API implementation and an annotation file (specifying issues and faults that the user may have decided to have the tool inject in these generated assets).

## Running OAS DB

The easiest way to run OAS DB is using the provided Dockerfile in the root of this repository to build a container with all the required dependencies.

## OAS DB CLI

OAS DB comes with a simple CLI (inside bin/oasdb) that expects a configuration file in the JSON format. A sample configuration file is presented below:

```
{
  "oas_seed_abs_path": "/absolute_path/incident_response.json", # Absolute path to an OpenAPI specification seed.
  "mock_api_server_url": "http://localhost:3000", # URL where the mock API will be reachable when running.
  "spec_issues": [
    "invalid_examples" # List of issues that affect the generated OpenAPI specification.
  ],
  "api_issues": [
    "broken_record_deletion" # List of issues that affect the generated Ruby mock API implementation.
  ],
  "generated_files_basename": "incident_response_invalid_examples" # The basename for the assets to be generated.
}
```

To run the CLI (from within the projects root folder), call it passing the absolute path to a configuration file:

```
bin/oasdb path_to_config.json
```

## Extra information

More detailed docs are coming in the future. For now, please refer to the associated ISSRE 2021 submission. It explains
in greater depth how OAS DB works.
