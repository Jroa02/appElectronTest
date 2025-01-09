#!/bin/bash

TAG1=$1
TAG2=$2
OUTPUT_FILE="ultimos_cambios.md"

# Verificar si el primer tag existe
if [ -z "$TAG1" ]; then
  echo "Error: El primer tag debe ser proporcionado como argumento." 
  exit 1
fi

# Generar encabezado del archivo Markdown
echo "# Últimos Cambios en el Repositorio" > $OUTPUT_FILE
echo "A continuación se listan los últimos commits realizados entre los tags $TAG1 y $TAG2:" >> $OUTPUT_FILE
echo "## Commits:" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Verificar si el segundo tag existe
if git rev-parse "$TAG2" >/dev/null 2>&1; then
  # Si ambos tags existen, se muestran los commits entre ellos
  echo "Mostrando commits entre $TAG1 y $TAG2..." >> $OUTPUT_FILE
  git log $TAG1..$TAG2 --oneline --pretty=format:"- %s" >> $OUTPUT_FILE
else
  # Si el segundo tag no existe, mostrar los commits desde el inicio del repo hasta el primer tag
  echo "El tag $TAG2 no existe, mostrando commits hasta $TAG1..." >> $OUTPUT_FILE
  git log --oneline $TAG1 --pretty=format:"- %s" >> $OUTPUT_FILE
fi

# Agregar título de Contribuidores
echo "" >> $OUTPUT_FILE
echo "## Contribuidores:" >> $OUTPUT_FILE

# Obtener la lista de contribuidores (autores de los commits)
git log $TAG1..$TAG2 --pretty=format:"%an" | sort | uniq | while read contributor; do
  echo "- $contributor" >> $OUTPUT_FILE
done

echo "Archivo $OUTPUT_FILE generado con éxito."
