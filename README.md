# Civit Downloader

This is a simple bash script for downloading Civit LORAs, Embeddings and Checkpoints into your Fooocus directories. It also tries to organize them in a senible way for use in the application, because the default names are generally unusable:

LORAs are classified by their top level tag (style, character, etc.) and put under a subdirectory based on that,, then a subdirectory for the Model name, and the model file itself is renamed to the version name. Using the `-n|--no-rename` flag will keep the filename to make inline loading work more as expected.

Checkpoints will ask you for a classification subdirectory, but are otherwise named the same way. You can define the classification subdirectory using the `-s|--subdir` flag.

Embeddings do not have classification subdirectories.

It stores your API key and models directory in `~/.civitai/download.config`

Requirements: jq and curl

    Usage: civit_download [OPTIONS]
    Options:
      -m, --model <modelID>           Download model files
      -v, --modelversion <versionID>  Download model version file
      -r, --reconfigure               Remove config file and ask for API key/models directory
      -n, --no-rename                 Do not rename downloaded files
      -s, --subdir <subdir>           Specify subdirectory for model files underneath type directory

## Installation

Download the raw bash, mark as executable, and copy it to sompleace in your PATH. e.g:

    chmod +x civit_download.sh
    cp civit_download.sh /usr/local/bin/civit_download

## TODO

* Other things?
* specify subfolder as flag for checkpoint version download
* flag to not rename file
