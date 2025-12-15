/* ========================================
   main.c - Point d'entrée du programme
   ======================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "avl.h"
#include "histo.h"
#include "leaks.h"

#define MAX_LINE 1024

int main(int argc, char *argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Erreur: Nombre d'arguments insuffisant\n");
        return 1;
    }

    char *mode = argv[1];
    char *input_file = argv[2];
    char *output_file = argv[3];

    // Vérification du fichier d'entrée
    FILE *file = fopen(input_file, "r");
    if (file == NULL) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier %s\n", input_file);
        return 2;
    }
    fclose(file);

    // Traitement selon le mode
    if (strcmp(mode, "max") == 0) {
        return process_max(input_file, output_file);
    } 
    else if (strcmp(mode, "src") == 0) {
        return process_src(input_file, output_file);
    } 
    else if (strcmp(mode, "real") == 0) {
        return process_real(input_file, output_file);
    } 
    else if (strcmp(mode, "leaks") == 0) {
        if (argc < 5) {
            fprintf(stderr, "Erreur: Mode leaks nécessite un identifiant d'usine\n");
            return 1;
        }
        char *facility_id = argv[3];
        char *leak_output = argv[4];
        return process_leaks(input_file, facility_id, leak_output);
    }
    else {
        fprintf(stderr, "Erreur: Mode inconnu (%s)\n", mode);
        return 1;
    }

    return 0;
}
