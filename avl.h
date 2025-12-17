/*
 * avl.h - En-tete pour l'arbre AVL
 * Projet C-Wildwater - Gestion des usines de traitement d'eau
 * 
 * Cet arbre AVL permet de stocker les usines et leurs donnees
 * avec une complexite O(log n) pour la recherche et l'insertion.
 * 
 * Convention d'equilibre: eq = hauteur(droite) - hauteur(gauche)
 *   eq > 0 : sous-arbre droit plus haut
 *   eq < 0 : sous-arbre gauche plus haut
 *   eq = 0 : arbre equilibre
 */

#ifndef AVL_H
#define AVL_H

#include <stdio.h>

/* Structure pour une usine de traitement */
typedef struct Usine {
    char identifiant[50];      /* Identifiant unique de l'usine */
    double capacite_max;       /* Capacite maximale de traitement (k.m3) */
    double volume_capte;       /* Volume total capte par les sources (k.m3) */
    double volume_traite;      /* Volume reellement traite (k.m3) */
} Usine;

/* Noeud de l'arbre AVL */
typedef struct NoeudAVL {
    Usine usine;
    int eq;                    /* Facteur d'equilibre: droite - gauche */
    struct NoeudAVL *fg;       /* Fils gauche */
    struct NoeudAVL *fd;       /* Fils droit */
} NoeudAVL;

/* Fonctions utilitaires */
int max(int a, int b);
int min(int a, int b);
int max3(int a, int b, int c);
int min3(int a, int b, int c);

/* Creation d'un noeud */
NoeudAVL* creerNoeud(Usine usine);

/* Rotations pour equilibrer l'AVL */
NoeudAVL* rotationGauche(NoeudAVL *a);
NoeudAVL* rotationDroite(NoeudAVL *a);
NoeudAVL* doubleRotationGauche(NoeudAVL *a);
NoeudAVL* doubleRotationDroite(NoeudAVL *a);

/* Equilibrage */
NoeudAVL* equilibrerAVL(NoeudAVL *a);

/* Operations principales */
NoeudAVL* insererAVL(NoeudAVL *a, Usine usine, int *h);
NoeudAVL* rechercherAVL(NoeudAVL *racine, char *identifiant);

/* Parcours et liberation */
void parcoursInverseAVL(NoeudAVL *racine, FILE *fichier, int mode);
void libererAVL(NoeudAVL *racine);
int compterNoeuds(NoeudAVL *racine);

#endif
