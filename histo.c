/* ========================================
   histo.c - Implémentation histogrammes
   ======================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "avl.h"
#include "histo.h"

#define MAX_LINE 1024

// Traiter la capacité maximale des usines
int process_max(const char *input_file, const char *output_file) {
    FILE *input = fopen(input_file, "r");
    if (input == NULL) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir %s\n", input_file);
        return 2;
    }
    
    AVLNode *root = NULL;
    char line[MAX_LINE];
    
    // Lecture du fichier filtré: identifiant;capacite
    while (fgets(line, MAX_LINE, input) != NULL) {
        char identifier[256];
        double capacity;
        
        // Parser la ligne
        if (sscanf(line, "%255[^;];%lf", identifier, &capacity) == 2) {
            root = insert_avl(root, identifier, capacity);
            if (root == NULL) {
                fprintf(stderr, "Erreur: Échec d'insertion dans l'AVL\n");
                fclose(input);
                return 3;
            }
        }
    }
    
    fclose(input);
    
    // Écrire les résultats
    FILE *output = fopen(output_file, "w");
    if (output == NULL) {
        fprintf(stderr, "Erreur: Impossible de créer %s\n", output_file);
        free_avl(root);
        return 2;
    }
    
    // En-tête
    fprintf(output, "identifier;max volume (k.m³.year⁻¹)\n");
    
    // Écrire l'AVL (ordre alphabétique naturel)
    write_avl_inorder(root, output);
    
    fclose(output);
    free_avl(root);
    
    return 0;
}

// Traiter le volume total capté par les sources
int process_src(const char *input_file, const char *output_file) {
    FILE *input = fopen(input_file, "r");
    if (input == NULL) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir %s\n", input_file);
        return 2;
    }
    
    AVLNode *root = NULL;
    char line[MAX_LINE];
    
    // Lecture du fichier filtré: identifiant_usine;volume_capte
    while (fgets(line, MAX_LINE, input) != NULL) {
        char identifier[256];
        double volume;
        
        if (sscanf(line, "%255[^;];%lf", identifier, &volume) == 2) {
            root = insert_avl(root, identifier, volume);
            if (root == NULL) {
                fprintf(stderr, "Erreur: Échec d'insertion dans l'AVL\n");
                fclose(input);
                return 3;
            }
        }
    }
    
    fclose(input);
    
    // Écrire les résultats
    FILE *output = fopen(output_file, "w");
    if (output == NULL) {
        fprintf(stderr, "Erreur: Impossible de créer %s\n", output_file);
        free_avl(root);
        return 2;
    }
    
    fprintf(output, "identifier;source volume (k.m³.year⁻¹)\n");
    write_avl_inorder(root, output);
    
    fclose(output);
    free_avl(root);
    
    return 0;
}

// Traiter le volume réellement traité (avec fuites)
int process_real(const char *input_file, const char *output_file) {
    FILE *input = fopen(input_file, "r");
    if (input == NULL) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir %s\n", input_file);
        return 2;
    }
    
    AVLNode *root = NULL;
    char line[MAX_LINE];
    
    // Lecture du fichier filtré: identifiant_usine;volume_capte;pourcentage_fuite
    while (fgets(line, MAX_LINE, input) != NULL) {
        char identifier[256];
        double volume, leak_percent;
        
        if (sscanf(line, "%255[^;];%lf;%lf", identifier, &volume, &leak_percent) == 3) {
            // Calcul du volume réel après fuite dans le tronçon source->usine
            double real_volume = volume * (leak_percent / 100.0);
            
            root = insert_avl(root, identifier, real_volume);
            if (root == NULL) {
                fprintf(stderr, "Erreur: Échec d'insertion dans l'AVL\n");
                fclose(input);
                return 3;
            }
        }
    }
    
    fclose(input);
    
    // Écrire les résultats
    FILE *output = fopen(output_file, "w");
    if (output == NULL) {
        fprintf(stderr, "Erreur: Impossible de créer %s\n", output_file);
        free_avl(root);
        return 2;
    }
    
    fprintf(output, "identifier;real volume (k.m³.year⁻¹)\n");
    write_avl_inorder(root, output);
    
    fclose(output);
    free_avl(root);
    
    return 0;
}
