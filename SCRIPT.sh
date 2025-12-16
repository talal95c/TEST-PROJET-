#!/bin/bash

# =============================================================================
# c-wildwater.sh - Script de traitement des donnees de distribution d'eau
# Projet C-Wildwater - PreIng2 2025-2026
# 
# Ce script filtre les donnees avec grep/awk, appelle le programme C wildwater
# et genere les graphiques avec gnuplot.
# =============================================================================

# Enregistrement du temps de debut pour mesurer la duree d'execution
DEBUT=$(date +%s%3N)

# Repertoires du projet
                                                                                                                                            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODE_C_DIR="$SCRIPT_DIR/codeC"
GRAPHS_DIR="$SCRIPT_DIR/graphs"
TESTS_DIR="$SCRIPT_DIR/tests"
TEMP_DIR="$SCRIPT_DIR/tmp"

# =============================================================================
# Fonctions utilitaires
# =============================================================================

# Affiche les instructions d'utilisation du script
afficher_usage() {
    echo "Usage : $0 <fichier.dat> <commande> [options]"
    echo ""
    echo "Commandes disponibles :"
    echo "  histo {max|src|real|all}  - Generation d'histogrammes des usines"
    echo "  leaks \"<identifiant>\"     - Calcul des fuites pour une usine donnee"
    echo ""
    echo "Exemples d'utilisation :"
    echo "  $0 wildwater.dat histo max"
    echo "  $0 wildwater.dat histo src"
    echo "  $0 wildwater.dat leaks \"Facility complex #RH400057F\""
}

# Affiche un message d'erreur et termine le script
                                                                                                                                                                                            erreur() {
                                                                                                                                                                                                echo "Erreur : $1" >&2
                                                                                                                                                                                                afficher_duree
                                                                                                                                                                                                exit 1
                                                                                                                                                                                            }

# Affiche la duree totale d'execution du script
afficher_duree() {
    FIN=$(date +%s%3N)
    DUREE=$((FIN - DEBUT))
    echo ""
    echo "Duree totale d'execution : ${DUREE} ms"
}

# =============================================================================
# Verification des arguments de la ligne de commande
# =============================================================================

# Verifier qu'il y a au moins 2 arguments
if [ "$#" -lt 2 ]; then
    afficher_usage
    erreur "Nombre d'arguments insuffisant"
fi

FICHIER_DONNEES="$1"
COMMANDE="$2"
OPTION="$3"

# Verifier qu'il n'y a pas trop d'arguments
if [ "$#" -gt 3 ]; then
    erreur "Trop d'arguments fournis"
fi

# Verifier que le fichier de donnees existe
if [ ! -f "$FICHIER_DONNEES" ]; then
    erreur "Le fichier '$FICHIER_DONNEES' est introuvable"
fi

# Creer les repertoires necessaires s'ils n'existent pas
mkdir -p "$GRAPHS_DIR" "$TESTS_DIR" "$TEMP_DIR"

# =============================================================================
# Compilation du programme C avec make
# =============================================================================

echo "=== Verification de la compilation ==="

# Se deplacer dans le repertoire du code C
                                                                                                                                            cd "$CODE_C_DIR" || erreur "Impossible d'acceder au repertoire codeC"

# Verifier si l'executable existe, sinon compiler avec make
if [ ! -f "wildwater" ]; then
    echo "Compilation du programme C avec make..."
    make
    if [ $? -ne 0 ]; then
        erreur "La compilation a echoue"
    fi
    echo "Compilation terminee avec succes"
else
    echo "L'executable wildwater existe deja"
fi

# Revenir au repertoire principal
                                                                                                                        cd "$SCRIPT_DIR" || erreur "Impossible de revenir au repertoire principal"

# =============================================================================
# TRAITEMENT HISTOGRAMME
# =============================================================================

if [ "$COMMANDE" = "histo" ]; then
    
    # Verification que l'option est bien fournie
    if [ "$#" -ne 3 ]; then
        erreur "La commande 'histo' necessite une option (max, src, real ou all)"
    fi
    
    # Verification que l'option est valide
    if [[ "$OPTION" != "max" && "$OPTION" != "src" && "$OPTION" != "real" && "$OPTION" != "all" ]]; then
        erreur "Option invalide : '$OPTION'. Options valides : max, src, real, all"
    fi
    
    echo "=== Generation d'histogramme : mode $OPTION ==="
                                                                                                                                                                                                                    
                                                                                                                                                                                                                    # Definition des noms de fichiers
                                                                                                                                                                                                                    DONNEES_FILTREES="$TEMP_DIR/donnees_filtrees.csv"
                                                                                                                                                                                                                    FICHIER_SORTIE="$TESTS_DIR/vol_$OPTION.dat"
    
    # =========================================================================
    # Filtrage des donnees avec grep et awk
    # =========================================================================
    
    echo "Filtrage des donnees avec grep et awk..."
    
    # Extraction des lignes d'usines (description de capacite maximale)
    # Format attendu : -;Usine;-;capacite;-
    echo "  -> Extraction des capacites maximales des usines..."
                                                                                                                                                                                                    grep -E "^-;(Plant #|Module #|Unit #|Facility complex #)" "$FICHIER_DONNEES" | \
                                                                                                                                                                                                        grep -E ";-;[0-9]+;-$" > "$TEMP_DIR/usines.csv"
    
    # Extraction des lignes de captage (source vers usine)
    # Format attendu : -;Source;Usine;volume;pourcentage
    echo "  -> Extraction des volumes captes par les sources..."
                                                                                                                                                                                                        grep -E "^-;(Source #|Well #|Spring #|Fountain #|Resurgence #)" "$FICHIER_DONNEES" | \
                                                                                                                                                                                                            grep -E ";(Plant #|Module #|Unit #|Facility complex #)" > "$TEMP_DIR/captages.csv"
    
    # Compter le nombre de lignes extraites
    NB_USINES=$(wc -l < "$TEMP_DIR/usines.csv")
    NB_CAPTAGES=$(wc -l < "$TEMP_DIR/captages.csv")
    echo "  -> $NB_USINES usines trouvees"
    echo "  -> $NB_CAPTAGES relations de captage trouvees"
    
    # Combiner les deux fichiers pour le programme C
    cat "$TEMP_DIR/usines.csv" "$TEMP_DIR/captages.csv" > "$DONNEES_FILTREES"
    
    # Verification que des donnees ont bien ete extraites
    if [ ! -s "$DONNEES_FILTREES" ]; then
        rm -f "$DONNEES_FILTREES" "$TEMP_DIR"/*.csv
        erreur "Aucune donnee n'a pu etre extraite du fichier"
    fi
    
    # =========================================================================
    # Appel du programme C
    # =========================================================================
    
    echo "Appel du programme C pour le traitement..."
                                                                                                                            "$CODE_C_DIR/wildwater" histo "$OPTION" "$DONNEES_FILTREES" "$FICHIER_SORTIE"
    
    # Verification du code retour du programme C
    if [ $? -ne 0 ]; then
        rm -f "$DONNEES_FILTREES" "$TEMP_DIR"/*.csv
        erreur "Le programme C a retourne une erreur"
    fi
    
    echo "Traitement des donnees termine avec succes"
    
    # =========================================================================
    # Preparation des donnees pour gnuplot
    # =========================================================================
    
    echo "Preparation des donnees pour les graphiques..."
    
    FICHIER_PETITES="$TEMP_DIR/petites_$OPTION.dat"
    FICHIER_GRANDES="$TEMP_DIR/grandes_$OPTION.dat"
    
    if [ "$OPTION" = "all" ]; then
        # Mode bonus : trier par le total des 3 colonnes
        awk -F';' 'NR>1 {total=$2+$3+$4; print $0";"total}' "$FICHIER_SORTIE" | \
            sort -t';' -k5 -n | head -50 | \
            awk -F';' '{print $1";"$2";"$3";"$4}' > "$FICHIER_PETITES"
        
        awk -F';' 'NR>1 {total=$2+$3+$4; print $0";"total}' "$FICHIER_SORTIE" | \
            sort -t';' -k5 -nr | head -10 | \
            awk -F';' '{print $1";"$2";"$3";"$4}' > "$FICHIER_GRANDES"
    else
        # Mode simple : trier par la colonne 2 (valeur)
        awk -F';' 'NR>1' "$FICHIER_SORTIE" | sort -t';' -k2 -n | head -50 > "$FICHIER_PETITES"
        awk -F';' 'NR>1' "$FICHIER_SORTIE" | sort -t';' -k2 -nr | head -10 > "$FICHIER_GRANDES"
    fi
    
    # =========================================================================
    # Definition des parametres pour gnuplot selon le mode
    # =========================================================================
    
    case "$OPTION" in
        max)
            YLABEL="Volume (M.m³.year⁻¹)"
            TITRE="Capacite maximale de traitement"
            ;;
        src)
            YLABEL="Volume (M.m³.year⁻¹)"
            TITRE="Volume capte par les sources"
            ;;
        real)
            YLABEL="Volume (M.m³.year⁻¹)"
            TITRE="Volume reellement traite"
            ;;
        all)
            YLABEL="Volume (M.m³.year⁻¹)"
            TITRE="Donnees combinees (reel, perdu, disponible)"
            ;;
    esac
    
    # =========================================================================
    # Generation des graphiques avec gnuplot
    # =========================================================================
    
    echo "Generation des graphiques avec gnuplot..."
    
    if [ "$OPTION" = "all" ]; then
        # Graphiques empiles pour le mode bonus
        gnuplot <<EOF
set terminal png size 1400,900
set datafile separator ";"
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.8
set xtics rotate by -45 font ",8"
set grid y
set key outside right top

set output "$GRAPHS_DIR/vol_${OPTION}_small.png"
set title "50 plus petites usines - $TITRE"
set ylabel "$YLABEL"
set xlabel "Identifiant de l'usine"
plot "$FICHIER_PETITES" using 2:xtic(1) title "Volume reel" lc rgb "#6699FF", \
     '' using 3 title "Volume perdu" lc rgb "#FF6666", \
     '' using 4 title "Capacite disponible" lc rgb "#99FF99"

set output "$GRAPHS_DIR/vol_${OPTION}_big.png"
set title "10 plus grandes usines - $TITRE"
set ylabel "$YLABEL"
set xlabel "Identifiant de l'usine"
plot "$FICHIER_GRANDES" using 2:xtic(1) title "Volume reel" lc rgb "#6699FF", \
     '' using 3 title "Volume perdu" lc rgb "#FF6666", \
     '' using 4 title "Capacite disponible" lc rgb "#99FF99"
EOF
    else
        # Graphiques simples pour les modes max, src, real
        gnuplot <<EOF
set terminal png size 1400,900
set datafile separator ";"
set style data histograms
set style fill solid border -1
set boxwidth 0.9
set xtics rotate by -45 font ",8"
set grid y

set output "$GRAPHS_DIR/vol_${OPTION}_small.png"
set title "50 plus petites usines - $TITRE"
set ylabel "$YLABEL"
set xlabel "Identifiant de l'usine"
plot "$FICHIER_PETITES" using 2:xtic(1) notitle with histograms lc rgb "blue"

set output "$GRAPHS_DIR/vol_${OPTION}_big.png"
set title "10 plus grandes usines - $TITRE"
set ylabel "$YLABEL"
set xlabel "Identifiant de l'usine"
plot "$FICHIER_GRANDES" using 2:xtic(1) notitle with histograms lc rgb "red"
EOF
    fi
    
    # Verification de la generation des graphiques
    if [ $? -eq 0 ]; then
        echo "Graphiques generes avec succes :"
        echo "  - $GRAPHS_DIR/vol_${OPTION}_small.png (50 plus petites usines)"
        echo "  - $GRAPHS_DIR/vol_${OPTION}_big.png (10 plus grandes usines)"
    else
        erreur "Echec lors de la generation des graphiques avec gnuplot"
    fi
    
    # Nettoyage des fichiers temporaires
    rm -f "$DONNEES_FILTREES" "$FICHIER_PETITES" "$FICHIER_GRANDES" "$TEMP_DIR"/*.csv

# =============================================================================
# TRAITEMENT CALCUL DES FUITES
# =============================================================================

elif [ "$COMMANDE" = "leaks" ]; then
    
    # Verification que l'identifiant est fourni
    if [ "$#" -ne 3 ]; then
        erreur "La commande 'leaks' necessite un identifiant d'usine"
    fi
    
    IDENTIFIANT_USINE="$3"
    
    echo ""
    echo "=== Calcul des fuites pour l'usine : $IDENTIFIANT_USINE ==="
    
    # Definition des noms de fichiers
    FICHIER_SORTIE="$TESTS_DIR/leaks.dat"
    RESULTAT_TEMPORAIRE="$TEMP_DIR/resultat_temp.dat"
    
    # Creer le fichier avec l'en-tete s'il n'existe pas encore
    if [ ! -f "$FICHIER_SORTIE" ]; then
        echo "identifier;Leak volume (M.m³.year⁻¹)" > "$FICHIER_SORTIE"
        echo "Creation du fichier de sortie avec en-tete"
    fi
    
    # =========================================================================
    # Appel du programme C
    # =========================================================================
    
    # Le programme C lit directement le fichier complet et extrait
    # toutes les informations necessaires pour l'usine specifiee
    echo "Appel du programme C pour le calcul des fuites..."
    "$CODE_C_DIR/wildwater" leaks "$IDENTIFIANT_USINE" "$FICHIER_DONNEES" "$RESULTAT_TEMPORAIRE"
    
    # Verification du code retour du programme C
    if [ $? -ne 0 ]; then
        rm -f "$RESULTAT_TEMPORAIRE"
        erreur "Le programme C a retourne une erreur"
    fi
    
    # Ajouter le resultat au fichier principal (mode append)
    if [ -f "$RESULTAT_TEMPORAIRE" ]; then
        cat "$RESULTAT_TEMPORAIRE" >> "$FICHIER_SORTIE"
        rm -f "$RESULTAT_TEMPORAIRE"
    fi
    
    echo "Calcul des fuites termine avec succes"
    echo "Resultat ajoute dans le fichier : $FICHIER_SORTIE"
    
    # Afficher le dernier resultat calcule
    echo ""
    echo "Dernier resultat calcule :"
    tail -1 "$FICHIER_SORTIE"

# =============================================================================
# Commande inconnue
# =============================================================================

else
    erreur "Commande inconnue : '$COMMANDE'. Commandes valides : histo, leaks"
fi

# =============================================================================
# Affichage de la duree totale d'execution
# =============================================================================

afficher_duree

exit 0
