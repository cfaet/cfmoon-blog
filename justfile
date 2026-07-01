# justfile for The Aleph Project

# --- Aliases & Variables ---


# The name of our Hakyll executable, compiled by Nix/cabal
hakyll-bin := "cabal run blog"


# --- Core Commands ---

# Build the Hakyll site from scratch.
# This will be our main production build command.
build:
    @echo ">>> Compiling The Aleph Project with Hakyll..."
    {{hakyll-bin}} build
    @echo ">>> Build complete. Site generated in _site/ directory."

# Clean up all generated files and caches.
# Useful for forcing a complete, fresh rebuild.
clean:
    @echo ">>> Cleaning project directory..."
    {{hakyll-bin}} clean
    @echo ">>> Done."

# Combination of clean and build.
rebuild: clean build

# Start a local development server to preview the site.
# The server will be accessible at http://127.0.0.1:8000
serve: rebuild
    @echo ">>> Starting local development server at http://127.0.0.1:8000"
    @echo ">>> Press CTRL+C to stop."
    {{hakyll-bin}} server

# The master development command!
# This command automatically rebuilds the site when files change
# and runs a local server. This is what we'll use most of the time.
watch:
    @echo ">>> Entering watch mode. Rebuilding on file changes..."
    {{hakyll-bin}} watch

# Gather files and combine them into a single file, useful to provide code for Lucia
cat := require("cat")
gather-files paths:
	#!/usr/bin/env zsh
	output_filename="concatenated.$(shuf -i 1-10000 -n 1)"
	input_paths=({{paths}})
	echo "Got these paths: $input_paths \nConcatenating now..."
	foreach path ("${input_paths[@]}")
	  echo "\n=== $path ===\n" >> "$output_filename"
	  {{cat}} "$path" >> "$output_filename"
	  echo "\n" >> "$output_filename"
	end
	echo "Concatenated files to $output_filename"
	
