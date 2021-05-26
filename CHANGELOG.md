Changelog is kept at [GitHub](https://github.com/Dronehub/minijson/releases),
here's only the changelog for the version in development

# v1.5

* fixed a bug with wrong type of dict and string was chosen 
  for a dict which contains exactly 65535 keys.
  Since this is rare in production, it can wait.
  MiniJSON is still generated correctly.
* fixed a bug with dumping strings longer than 255 characters
  would not return a length
* fixed a bug with unserializing some strings

