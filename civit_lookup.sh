#! /bin/bash
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install jq and try again."
  exit 1
fi


if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Please install curl and try again."
  exit 1
fi


CONFIG_FILE=~/.civitai/download.config

getmetatype () {
  if [[ $defined_mt == false ]]; then
    if [[ $model_type == "loras" || $model_type == "embeddings" ]]; then
      model_metatype="unknown"
      for metatype in "${model_metatypes[@]}"; do
        if echo "$parent" | jq -r '.tags[]' | grep -q "$metatype"; then
          model_metatype="$metatype"
          break
        fi
      done
    elif [[ $model_type == "checkpoints" ]]; then
      # read -p "Model subdirectory (default: general): " model_metatype
      model_metatype=${model_metatype:-general}      
    fi
  fi
  # Ask user for model metatype

}


defined_mt=false
num_results=10
# NO_RENAME=false
# LINK=false
# SKIPIFEXIST=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -m|--model)
      mode="models"
      shift
      model="$1"
      ;;
    -v|--modelversion)
      mode="model-versions"
      shift
      modelversion="$1"
      ;;
    -r| --reconfigure)
      rm -f $CONFIG_FILE
      echo "Configuration file removed."
      ;;
    -n| --numresults)
      shift
      num_results="$1"
      ;;
    -s| --search)
      shift
      query="$1"
      mode="search"
      ;;
    -sd | --sort-downloaded)
      sort="Most%20Downloaded"
      ;;
    -sr | --sort-rated)
      sort="Highest%20Rated"
      ;;
    -sn | --sort-newest)
      sort="Newest"
      ;;
    -mt | --metatype)
      defined_mt=true
      shift
      model_metatype="$1"
      #check if metatype is valid valid types: Checkpoint, TextualInversion, Hypernetwork, AestheticGradient, LORA, Controlnet, Poses
      model_metatypes=("Checkpoint" "TextualInversion" "Hypernetwork" "AestheticGradient" "LORA" "Controlnet" "Poses")
      valid_metatype=false
      for metatype in "${model_metatypes[@]}"; do
        if [[ $model_metatype == $metatype ]]; then
        valid_metatype=true
          break
        fi
      done
      if [[ $valid_metatype == false ]]; then
        echo "Invalid metatype. Valid metatypes are: Checkpoint, TextualInversion, Hypernetwork, AestheticGradient, LORA, Controlnet, Poses"
        exit 1
      fi 
      defined_mt=true
      ;;
    # -k| --skip)
    #   SKIPIFEXIST=true
    #   ;;
    # -l| --link)
    #   LINK=true
    #   NO_RENAME=false
    #   ;;
    *)
      echo "Unknown option: $key"
      exit 1
      ;;
  esac
  shift
done

if [[ -z $mode ]]; then
        echo "
Usage: civit_download [OPTIONS]
Options:
  -m, --model <modelID>           Download model files
  -v, --modelversion <versionID>  Download model version file
  -r, --reconfigure               Reconfigure the download script

  Configuration: options are stored in $CONFIG_FILE
"
  exit 1
fi
if [[ ! -f $CONFIG_FILE ]]; then
  echo "Config file not found. Please provide the following information:"
  read -p "API Key: " api_key
  read -p "Models Directory: " models_dir

  echo "api_key=\"$api_key\"" >> $CONFIG_FILE
  echo "models_dir=\"$models_dir\"" >> $CONFIG_FILE

  echo "Configuration saved to $CONFIG_FILE"
fi

# Load the config file
source $CONFIG_FILE

CIVIT_API_URL="https://civitai.com/api/v1"
model_metatypes=("character" "style" "clothing" "celebrity" "concept" "base model" "poses" "background" "tool" "buildings" "vehicle" "objects" "animal" "action" "assets")

if [[ $mode == "models" ]]; then
  echo "Selected mode: model"
  echo "Model: $model"
  response=$(curl -s -L "$CIVIT_API_URL/$mode/$model")
  if [[ $? -ne 0 ]]; then
    echo "Failed to retrieve model manifest from API."
    exit 1
  fi


  model_name=$(echo "$response" | jq -r '.name')
  model_type=$(echo "$response" | jq -r '.type')
  if [[ $model_type == "LORA" || $model_type == "LoCon" ]]; then
    model_type="loras"
    parent=$response
    getmetatype
    echo "Model Name: $model_name"
    echo "Model Type: $model_type"
    echo "Model Metatype: $model_metatype"
    model_versions_count=$(echo "$response" | jq '.modelVersions | length')
    echo "Number of Model Versions: $model_versions_count"
    if [[ $model_versions_count -eq 0 ]]; then
      echo "No model versions found for model $model."
      exit 1
    fi
    # Make the model_name filename safe
    # safe_model_name=$(echo "$model_name" | tr ' ' '_'| tr -dc '[:alnum:]\n\r_')
    
    # Create the target directory
    # target_dir="$models_dir/$model_type/$model_metatype/$safe_model_name"
    # mkdir -p "$target_dir"
    # if [[ $? -ne 0 ]]; then
    #   echo "Failed to create target directory: $target_dir"
    #   exit 1
    # fi
    
    # echo "Target Directory: $target_dir"

    # download_all
  elif [[ $model_type == "TextualInversion" ]]; then
    model_type="embeddings"
    echo "Model Name: $model_name"
    echo "Model Type: $model_type"
    model_versions_count=$(echo "$response" | jq '.modelVersions | length')
    echo "Number of Model Versions: $model_versions_count"
    if [[ $model_versions_count -eq 0 ]]; then
      echo "No model versions found for model $model."
      exit 1
    fi
    # Make the model_name filename safe
    # safe_model_name=$(echo "$model_name" | tr ' ' '_'| tr -dc '[:alnum:]\n\r_')
    
    # Create the target directory
  #   target_dir="$models_dir/$model_type/$safe_model_name"
  #   mkdir -p "$target_dir"
  #   if [[ $? -ne 0 ]]; then
  #     echo "Failed to create target directory: $target_dir"
  #     exit 1
  #   fi
    
  #   echo "Target Directory: $target_dir"

  #   download_all
  elif [[ $model_type == "Checkpoint" ]]; then
    model_type="checkpoints"
    model_versions_count=$(echo "$response" | jq '.modelVersions | length')
    echo "Number of Model Versions: $model_versions_count"
    # Enumerate and list model versions
    for ((i=0; i<$model_versions_count; i++)); do
      version_id=$(echo "$response" | jq -r ".modelVersions[$i].id")
      version_name=$(echo "$response" | jq -r ".modelVersions[$i].name")
      echo "[$i] $version_name (ID: $version_id)"
    done

    # Prompt user to select a model version to download
    # read -p "Enter the number of the model version to download: " version_number

    # Validate user input
    # if ! [[ "$version_number" =~ ^[0-9]+$ ]] || (( version_number < 0 || version_number >= model_versions_count )); then
    #   echo "Invalid input. Please enter a valid number."
    #   exit 1
    # fi

    # Get the selected model version details
    # selected_version=$(echo "$response" | jq -r ".modelVersions[$version_number]")
    # version_name=$(echo "$selected_version" | jq -r ".name")
    # version_files=$(echo "$response" | jq -r ".modelVersions[$version_number].files[] | select(.primary == true)")
    # if [[ -z $version_files ]]; then
    #   echo "No primary file found for model version $version_name."
    #   exit 1
    # fi
    # file_name=$(echo "$version_files" | jq -r ".name")
    # file_url=$(echo "$version_files" | jq -r ".downloadUrl")
    # Extract necessary information from the selected model version
  
    getmetatype

    # Create the target directory
    # target_dir="$models_dir/$model_type/$model_metatype/$safe_model_name"
    # mkdir -p "$target_dir"
    # if [[ $? -ne 0 ]]; then
    #   echo "Failed to create target directory: $target_dir"
    #   exit 1
    # fi

    # newfilename

    # skipcheck
    # Download the file
    # echo "Downloading Version '$version_name' as '$safe_file_name' "
    # curl -L -o "$target_dir/$safe_file_name" -H "Authorization: Bearer $api_key" "$file_url"
    # if [[ $? -ne 0 ]]; then
    #   echo "Failed to download file: $file_name"
    #   exit 1
    # fi
    # echo "File downloaded: $safe_file_name"
    # makelink
    fi

  


elif [[ $mode == "model-versions" ]]; then
  echo "Selected mode: modelversion"
  response=$(curl -s -L "$CIVIT_API_URL/$mode/$modelversion")
  if [[ $? -ne 0 ]]; then
    echo "Failed to retrieve model version information from API."
    exit 1
  fi
  model_versions=$(echo "$response" | jq -r '.[]')
  if [[ -z $model_versions ]]; then
    echo "No model versions found."
    exit 1
  fi

  version_name=$(echo "$response" | jq -r '.name')
  version_id=$(echo "$response" | jq -r '.id')
  model_id=$(echo "$response" | jq -r '.modelId')
  model_name=$(echo "$response" | jq -r '.model.name')
  model_type=$(echo "$response" | jq -r '.model.type')
  echo "Model Name: $model_name"
  echo "Model Type: $model_type"
  echo "Model ID: $model_id"
  echo "Model Version Name: $version_name"
  echo "Model Version ID: $version_id"

  if [[ $model_type == "LORA" || $model_type == "LoCon" ]]; then
    model_type="loras"
    parent=$(curl -s -L "$CIVIT_API_URL/models/$model_id")
    if [[ $? -ne 0 ]]; then
      echo "Failed to retrieve model information from API."
      exit 1
    fi


    getmetatype
    echo "Model Metatype: $model_metatype"
    # Get the primary file
    version_files=$(echo "$response" | jq -r '.files[] | select(.primary == true)')
    if [[ -z $version_files ]]; then
      echo "No primary file found for model version $version_name."
      exit 1
    fi

  elif [[ $model_type == "Checkpoint" ]]; then
    model_type="checkpoints"
    # Get the primary file
    version_files=$(echo "$response" | jq -r '.files[] | select(.primary == true)')
    if [[ -z $version_files ]]; then
      echo "No primary file found for model version $version_name."
      exit 1
    fi
    getmetatype
  elif [[ $model_type == "TextualInversion" ]]; then
    model_type="embeddings"
    parent=$(curl -s -L "$CIVIT_API_URL/models/$model_id")
    if [[ $? -ne 0 ]]; then
      echo "Failed to retrieve model information from API."
      exit 1
    fi


    getmetatype
    echo "Model Metatype: $model_metatype"
    # Get the primary file
    version_files=$(echo "$response" | jq -r '.files[] | select(.primary == true)')
    if [[ -z $version_files ]]; then
      echo "No primary file found for model version $version_name."
      exit 1
    fi
  else
    echo "Unknown Model Type"
  fi

elif [[ $mode == "search" ]]; then
  echo "Selected mode: search"
  curlstr="$CIVIT_API_URL/models?query=$query"
  addecho=""
  if [[ $defined_mt == true ]]; then
    curlstr="$curlstr&types=$model_metatype"
    addecho="$addecho of metatype: $model_metatype"
  fi
  if [[ -n $sort ]]; then
    curlstr="$curlstr&sort=$sort"
    addecho="$addecho sorted by ${sort//%20/ }"
  fi

  response=$(curl -s -L "$curlstr")
  items=$(echo "$response" | jq -r '.items[] | .name, .id, .type')
  if [[ -z $items ]]; then
    echo "No results found for query: $query"
    exit 1
  fi
  echo "Top $num_results search results for query: '$query'"
  echo "$addecho"
  for ((i=0; i<$num_results; i++)); do
    model_id=$(echo "$response" | jq -r ".items[$i].id")
    if [[ $model_id == "null" ]]; then
      echo "No more results found."
      break
    fi
    model_name=$(echo "$response" | jq -r ".items[$i].name")
    model_type=$(echo "$response" | jq -r ".items[$i].type")
    getmetatype

    echo "[$i] $model_name (ID: $model_id, Type: $model_type)"
  done

fi
