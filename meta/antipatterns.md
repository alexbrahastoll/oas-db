# Antipatterns present in OAS DB and their definition

This document contains the list of antipatterns present in OAS DB and their respective definitions. If you need a structured list of the covered antipatterns (i.e., one that is easy to consume programmatically), see meta/antipatterns.json.

For the full list of references cited in this document, see the final section [References](#references).

## Amorphous URI

Simplified name: amorphous_uri <br />
Reference: 1

### Description

Amorphous URIs are those that contain symbols (other than - and _), trailing symbols (any symbol, such as a trailing slash) or extensions (e.g., http://example.com/my-path.jsp). URIs that diverge from the most common API path case convention (e.g., camelCase, lower_snake_case etc) or that do not follow any convention at all should also be classified as amorphous URIs.

### Examples

- /my~path
- /my-path/
- /my-path.extension
- /READORDERS

# References

1. BRABRA, H.; MTIBAA, A.; PETRILLO, F.; MERLE, P.; SLIMAN, L.; MOHA, N.;GAALOUL, W.; GUÉHÉNEUC, Y.-G.; BENATALLAH, B.; GARGOURI, F. On semantic detection of cloud API (anti)patterns. Information and Software Technology, Elsevier B.V., v. 107, p. 65–82, 2019.
