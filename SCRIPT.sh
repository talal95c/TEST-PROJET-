#!/bin/bash

# Script principal du projet C-Wildwater
# Gere le traitement des donnees de distribution d'eau

# Enregistrement du temps de debut
START_TIME=$(date +%s%3N)

# Fonction pour afficher la duree d'execution
afficher_duree() {
    END_TIME=$(date +%s%3N)
    DURATION=$((END_TIME - START_TIME))
    echo ""
    echo "Durée totale d'exécution : ${DURATION} ms"
}

# Verification du nombre d'arguments minimum
if [ "$#" -lt 2 ]; then
    echo "Erreur : Nombre d'arguments insuffisant"
    echo "Usage : $0 <fichier.dat> <action> [options]"
    echo ""
    echo "Actions disponibles :"
    echo "  histo {max|src|real|all}  - Génère des histogrammes"
    echo "  leaks \"<identifiant>\"     - Calcule les fuites d'une usine"
    echo ""
    echo "Exemples :"
    echo "  $0 donnees.dat histo max"
    echo "  $0 donnees.dat leaks \"Facility complex #RH400057F\""
    afficher_duree
    exit 1
fi

# Recuperation des arguments
DATA_FILE="$1"
ACTION="$2"
OPTION="$3"

# Verification qu'il n'y a pas trop d'arguments
if [ "$#" -gt 3 ]; then
    echo "Erreur : Trop d'arguments fournis"
    afficher_duree
    exit 1
fi

# Verification de l'existence du fichier de donnees
if [ ! -f "$DATA_FILE" ]; then
    echo "Erreur : fichier $DATA_FILE introuvable"
    afficher_duree
    exit 1
fi

# Creation des repertoires necessaires
mkdir -p graphs tests tmp

# Verification et compilation du programme C si necessaire
if [ ! -f "./wildwater" ]; then
    echo "Compilation du programme C..."
    make
    if [ $? -ne 0 ]; then
        echo "Erreur : échec de la compilation"
        afficher_duree
        exit 1
    fi
    echo "Compilation réussie"
else
    echo "Executable déjà présent"
fi

# Traitement selon l'action demandee
if [ "$ACTION" = "histo" ]; then
    # Verification de la presence de l'option
    if [ "$#" -ne 3 ]; then
        echo "Erreur : l'action 'histo' nécessite une option"
        echo "Usage : $0 <fichier.dat> histo {max|src|real|all}"
        afficher_duree
        exit 1
    fi
    
    # Verification que l'option est valide
    if [[ "$OPTION" != "max" && "$OPTION" != "src" && "$OPTION" != "real" && "$OPTION" != "all" ]]; then
        echo "Erreur : option invalide ($OPTION)"
        echo "Options valides : max, src, real, all"
        afficher_duree
        exit 1
    fi
    
  
    echo "=== Génération d'histogramme : mode $OPTION ==="
    
                                                                                                        # Preparation des fichiers temporaires
                                                                                                        TMP_USINES="tmp/usines.tmp"
                                                                                                        TMP_CAPTAGES="tmp/captages.tmp"
                                                                                                        TMP_FILTERED="tmp/filtered_data.tmp"
                                                                                                        OUTPUT_FILE="tests/histo_${OPTION}.dat"
                                                                                                        
                                                                                                        # Filtrage des donnees avec grep et awk
                                                                                                        echo "Extraction des données..."
                                                                                                        
                                                                                                        # Extraire les lignes des usines (capacite maximale)
                                                                                                        # Format: -;Usine;-;capacite;-
                                                                                                        grep -E "^-;(Plant|Module|Unit|Facility)" "$DATA_FILE" | \
                                                                                                            grep -E ";-;[0-9]+;-$" > "$TMP_USINES"
                                                                                                        
                                                                                                        # Extraire les lignes de captage (source -> usine)
                                                                                                        # Format: -;Source;Usine;volume;pourcentage
                                                                                                        grep -E "^-;(Source|Well|Spring|Fountain|Resurgence)" "$DATA_FILE" | \
                                                                                                            grep -E ";(Plant|Module|Unit|Facility)" > "$TMP_CAPTAGES"
                                                                                                        
                                                                                                        # Compter les lignes trouvees
                                                                                                        NB_USINES=$(wc -l < "$TMP_USINES")
                                                                                                        NB_CAPTAGES=$(wc -l < "$TMP_CAPTAGES")
                                                                                                        echo "  -> $NB_USINES usines trouvées"
                                                                                                        echo "  -> $NB_CAPTAGES captages trouvés"
    
    # Combiner les donnees pour le programme C
                                                                                                        cat "$TMP_USINES" "$TMP_CAPTAGES" > "$TMP_FILTERED"
    
    # Appel du programme C
    echo "Traitement des données..."
    ./wildwater histo "$OPTION" "$TMP_FILTERED" "$OUTPUT_FILE"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution du programme C"
        rm -f "$TMP_USINES" "$TMP_CAPTAGES" "$TMP_FILTERED"
        afficher_duree
        exit 1
    fi
    
    # Verification que le fichier de sortie existe
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "Erreur : le fichier de sortie n'a pas été créé"
        rm -f "$TMP_USINES" "$TMP_CAPTAGES" "$TMP_FILTERED"
        afficher_duree
        exit 1
    fi
    
    echo "Données filtres avec succès"
    
    # Generation des graphiques avec gnuplot
    
    echo "=== Génération des graphiques ==="
    
    # Fichiers temporaires pour les graphiques
                                                                                                            TMP_BIG="tmp/big_${OPTION}.tmp"
                                                                                                            TMP_SMALL="tmp/small_${OPTION}.tmp"
    
    # Selon le mode, trier et extraire les donnees
                                                                                                            if [ "$OPTION" = "all" ]; then
                                                                                                                # Mode all : 4 colonnes (id;real;lost;available)
                                                                                                                # Trier par somme des colonnes 2, 3 et 4
                                                                                                                awk -F';' 'NR>1 {
                                                                                                                    total = $2 + $3 + $4
                                                                                                                    print $0 ";" total
                                                                                                                }' "$OUTPUT_FILE" | sort -t';' -k5 -n -r | head -10 | \
                                                                                                                    awk -F';' '{print $1";"$2";"$3";"$4}' > "$TMP_BIG"
                                                                                                                
                                                                                                                awk -F';' 'NR>1 {
                                                                                                                    total = $2 + $3 + $4
                                                                                                                    print $0 ";" total
                                                                                                                }' "$OUTPUT_FILE" | sort -t';' -k5 -n | head -50 | \
                                                                                                                    awk -F';' '{print $1";"$2";"$3";"$4}' > "$TMP_SMALL"
                                                                                                            else
                                                                                                                # Mode simple : 2 colonnes (id;valeur)
                                                                                                                awk -F';' 'NR>1 {print $0}' "$OUTPUT_FILE" | \
                                                                                                                    sort -t';' -k2 -n -r | head -10 > "$TMP_BIG"
                                                                                                                
                                                                                                                awk -F';' 'NR>1 {print $0}' "$OUTPUT_FILE" | \
                                                                                                                    sort -t';' -k2 -n | head -50 > "$TMP_SMALL"
                                                                                                            fi
    
    # Definition des titres selon le mode
    if [ "$OPTION" = "max" ]; then
        TITLE_SUFFIX="Capacité maximale"
        YLABEL="Volume (M.m³)"
    elif [ "$OPTION" = "src" ]; then
        TITLE_SUFFIX="Volume capté"
        YLABEL="Volume (M.m³)"
    elif [ "$OPTION" = "real" ]; then
        TITLE_SUFFIX="Volume traité"
        YLABEL="Volume (M.m³)"
    else
        TITLE_SUFFIX="Données combinées"
        YLABEL="Volume (M.m³)"
    fi
    
    # Generation du graphique des 10 plus grandes usines
    echo "Création du graphique des 10 plus grandes usines..."
    
    if [ "$OPTION" = "all" ]; then
        # Graphique empile pour le mode all
        gnuplot <<EOF
set terminal png size 1200,800
set output "graphs/histo_${OPTION}_big.png"
set title "10 plus grandes usines - $TITLE_SUFFIX"
set xlabel "Identifiant usine"
set ylabel "$YLABEL"
set datafile separator ";"
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.8
set xtics rotate by -45 font ",10"
set key outside right top
set grid y

plot "$TMP_BIG" using 2:xtic(1) title "Volume traité" lc rgb "#6699FF", \
     '' using 3 title "Volume perdu" lc rgb "#FF6666", \
     '' using 4 title "Capacité disponible" lc rgb "#99FF99"
EOF
    else
        # Graphique simple
        gnuplot <<EOF
set terminal png size 1200,800
set output "graphs/histo_${OPTION}_big.png"
set title "10 plus grandes usines - $TITLE_SUFFIX"
set xlabel "Identifiant usine"
set ylabel "$YLABEL"
set datafile separator ";"
set style data histograms
set style fill solid border -1
set boxwidth 0.8
set xtics rotate by -45 font ",10"
set grid y

plot "$TMP_BIG" using 2:xtic(1) notitle lc rgb "#4477AA"
EOF
    fi
    
    if [ $? -eq 0 ]; then
        echo "  -> graphs/histo_${OPTION}_big.png créé"
    else
        echo "Erreur lors de la génération du graphique"
    fi
    
    # Generation du graphique des 50 plus petites usines
    echo "Création du graphique des 50 plus petites usines..."
    
    if [ "$OPTION" = "all" ]; then
        gnuplot <<EOF
set terminal png size 1600,800
set output "graphs/histo_${OPTION}_small.png"
set title "50 plus petites usines - $TITLE_SUFFIX"
set xlabel "Identifiant usine"
set ylabel "$YLABEL"
set datafile separator ";"
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.8
set xtics rotate by -90 font ",8"
set key outside right top
set grid y

plot "$TMP_SMALL" using 2:xtic(1) title "Volume traité" lc rgb "#6699FF", \
     '' using 3 title "Volume perdu" lc rgb "#FF6666", \
     '' using 4 title "Capacité disponible" lc rgb "#99FF99"
EOF
    else
        gnuplot <<EOF
set terminal png size 1600,800
set output "graphs/histo_${OPTION}_small.png"
set title "50 plus petites usines - $TITLE_SUFFIX"
set xlabel "Identifiant usine"
set ylabel "$YLABEL"
set datafile separator ";"
set style data histograms
set style fill solid border -1
set boxwidth 0.8
set xtics rotate by -90 font ",8"
set grid y

plot "$TMP_SMALL" using 2:xtic(1) notitle lc rgb "#4477AA"
EOF
    fi
    
    if [ $? -eq 0 ]; then
        echo "  -> graphs/histo_${OPTION}_small.png créé"
    else
        echo "Erreur lors de la génération du graphique"
    fi
    
    # Nettoyage des fichiers temporaires
    rm -f "$TMP_USINES" "$TMP_CAPTAGES" "$TMP_FILTERED" "$TMP_BIG" "$TMP_SMALL"
    
    echo ""
    echo "=== Traitement terminé ==="
    echo "Fichier de données : $OUTPUT_FILE"
    echo "Graphiques générés dans le dossier graphs/"
    
elif [ "$ACTION" = "leaks" ]; then
    # Verification de la presence de l'identifiant
    if [ "$#" -ne 3 ]; then
        echo "Erreur : l'action 'leaks' nécessite un identifiant d'usine"
        echo "Usage : $0 <fichier.dat> leaks \"<identifiant usine>\""
        afficher_duree
        exit 1
    fi
    
    # Verification que l'identifiant n'est pas vide
    if [ -z "$OPTION" ]; then
        echo "Erreur : identifiant d'usine vide"
        afficher_duree
        exit 1
    fi
    
    FACILITY_ID="$OPTION"
    echo ""
    echo "=== Calcul des fuites pour : $FACILITY_ID ==="
    
    OUTPUT_FILE="tests/leaks.dat"
    TMP_CAPTAGES="tmp/captages_usine.tmp"
    TMP_DISTRIB="tmp/distrib_usine.tmp"
    TMP_FILTERED="tmp/filtered_leaks.tmp"
    
    # Creation de l'en-tete si le fichier n'existe pas
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "identifier;Leak volume (M.m³.year⁻¹)" > "$OUTPUT_FILE"
    fi
    
    # Filtrage des donnees pour cette usine specifique
    echo "Extraction des données de l'usine..."
    
                                                                                                                                                    # Extraire les captages vers cette usine
                                                                                                                                                    grep -F "$FACILITY_ID" "$DATA_FILE" | \
                                                                                                                                                        grep -E "^-;(Source|Well|Spring|Fountain|Resurgence)" > "$TMP_CAPTAGES"
                                                                                                                                                    
                                                                                                                                                    # Extraire les troncons de distribution de cette usine
                                                                                                                                                    grep -F "$FACILITY_ID" "$DATA_FILE" | \
                                                                                                                                                        grep -v "^-;" > "$TMP_DISTRIB"
                                                                                                                                                    
                                                                                                                                                    # Extraire aussi les troncons usine -> stockage
                                                                                                                                                    grep -F "$FACILITY_ID" "$DATA_FILE" | \
                                                                                                                                                        grep -E "^-;.*Storage" >> "$TMP_DISTRIB"
    
                                                                                                                                                    # Compter les lignes trouvees
                                                                                                                                                    NB_CAPTAGES=$(wc -l < "$TMP_CAPTAGES")
                                                                                                                                                    NB_DISTRIB=$(wc -l < "$TMP_DISTRIB")
                                                                                                                                                    echo "  -> $NB_CAPTAGES captages trouvés"
                                                                                                                                                    echo "  -> $NB_DISTRIB tronçons de distribution trouvés"
    
    # Combiner les donnees
    cat "$TMP_CAPTAGES" "$TMP_DISTRIB" > "$TMP_FILTERED"
    
    # Appel du programme C
    echo "Calcul des fuites..."
    ./wildwater leaks "$FACILITY_ID" "$TMP_FILTERED" "$OUTPUT_FILE"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'exécution du programme C"
        rm -f "$TMP_CAPTAGES" "$TMP_DISTRIB" "$TMP_FILTERED"
        afficher_duree
        exit 1
    fi
    
    # Nettoyage des fichiers temporaires
    rm -f "$TMP_CAPTAGES" "$TMP_DISTRIB" "$TMP_FILTERED"
    
    echo ""
    echo "=== Traitement terminé ==="
    echo "Résultat ajouté dans : $OUTPUT_FILE"
    echo ""
    echo "Dernier résultat :"
    tail -1 "$OUTPUT_FILE"
    
else
    # Action invalide
    echo "Erreur : action invalide ($ACTION)"
    echo "Actions supportées : histo ou leaks"
    afficher_duree
    exit 1
fi

# Affichage de la duree d'execution
afficher_duree

exit 0
