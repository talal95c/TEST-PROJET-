/*
 * avl.c - Implementation de l'arbre AVL
 * Projet C-Wildwater
 * 
 * L'AVL est un arbre binaire de recherche equilibre.
 * L'equilibrage garantit une complexite O(log n).
 * 
 * Convention d'equilibre: eq = hauteur(droite) - hauteur(gauche)
 * Cela correspond a la convention du cours d'Informatique 3.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "avl.h"

/* ========== Fonctions utilitaires ========== */

/* Retourne le maximum de deux entiers */
int max(int a, int b) {
    return (a > b) ? a : b;
}

/* Retourne le minimum de deux entiers */
int min(int a, int b) {
    return (a < b) ? a : b;
}

/* Retourne le maximum de trois entiers */
int max3(int a, int b, int c) {
    return max(max(a, b), c);
}

/* Retourne le minimum de trois entiers */
int min3(int a, int b, int c) {
    return min(min(a, b), c);
}

/* ========== Creation de noeud ========== */

/* Cree un nouveau noeud avec les donnees de l'usine */
NoeudAVL* creerNoeud(Usine usine) {
    NoeudAVL *nouveau = (NoeudAVL*)malloc(sizeof(NoeudAVL));
    if (nouveau == NULL) {
        fprintf(stderr, "Erreur: allocation memoire echouee\n");
        exit(EXIT_FAILURE);
    }
    nouveau->usine = usine;
    nouveau->fg = NULL;
    nouveau->fd = NULL;
    nouveau->eq = 0;  /* Facteur d'equilibre initialise a 0 */
    return nouveau;
}

/* ========== Rotations ========== */

/*
 * Rotation gauche autour du noeud a
 * Utilisee quand l'arbre est desequilibre a droite (eq >= 2)
 * 
 *     a                  pivot
 *      \                /     \
 *     pivot    =>      a       fd
 *      /  \             \
 *     T2   fd           T2
 */
NoeudAVL* rotationGauche(NoeudAVL *a) {
    NoeudAVL *pivot = a->fd;
    int eq_a = a->eq;
    int eq_p = pivot->eq;

    /* Effectuer la rotation */
    a->fd = pivot->fg;
    pivot->fg = a;

    /* Mise a jour des facteurs d'equilibre selon le cours */
    a->eq = eq_a - max(eq_p, 0) - 1;
    pivot->eq = min3(eq_a - 2, eq_a + eq_p - 2, eq_p - 1);

    return pivot;
}

/*
 * Rotation droite autour du noeud a
 * Utilisee quand l'arbre est desequilibre a gauche (eq <= -2)
 * 
 *       a              pivot
 *      /              /     \
 *    pivot    =>     fg      a
 *    /  \                   /
 *   fg   T2                T2
 */
NoeudAVL* rotationDroite(NoeudAVL *a) {
    NoeudAVL *pivot = a->fg;
    int eq_a = a->eq;
    int eq_p = pivot->eq;

    /* Effectuer la rotation */
    a->fg = pivot->fd;
    pivot->fd = a;

    /* Mise a jour des facteurs d'equilibre selon le cours */
    a->eq = eq_a - min(eq_p, 0) + 1;
    pivot->eq = max3(eq_a + 2, eq_a + eq_p + 2, eq_p + 1);

    return pivot;
}

/*
 * Double rotation gauche (rotation droite-gauche)
 * Utilisee quand eq >= 2 et pivot->eq < 0
 */
NoeudAVL* doubleRotationGauche(NoeudAVL *a) {
    a->fd = rotationDroite(a->fd);
    return rotationGauche(a);
}

/*
 * Double rotation droite (rotation gauche-droite)
 * Utilisee quand eq <= -2 et pivot->eq > 0
 */
NoeudAVL* doubleRotationDroite(NoeudAVL *a) {
    a->fg = rotationGauche(a->fg);
    return rotationDroite(a);
}

/* ========== Equilibrage ========== */

/*
 * Equilibre l'arbre AVL si necessaire
 * Applique les rotations appropriees selon le facteur d'equilibre
 */
NoeudAVL* equilibrerAVL(NoeudAVL *a) {
    if (a->eq >= 2) {
        /* Desequilibre a droite */
        if (a->fd->eq >= 0) {
            return rotationGauche(a);
        } else {
            return doubleRotationGauche(a);
        }
    } else if (a->eq <= -2) {
        /* Desequilibre a gauche */
        if (a->fg->eq <= 0) {
            return rotationDroite(a);
        } else {
            return doubleRotationDroite(a);
        }
    }
    return a;  /* Pas de reequilibrage necessaire */
}

/* ========== Insertion ========== */

/*
 * Insere une usine dans l'AVL et reequilibre si necessaire
 * h: pointeur pour indiquer si la hauteur a change
 *    h = 1  -> hauteur augmentee
 *    h = 0  -> hauteur inchangee
 *    h = -1 -> hauteur diminuee
 */
NoeudAVL* insererAVL(NoeudAVL *a, Usine usine, int *h) {
    int cmp;

    /* Cas de base: arbre vide */
    if (a == NULL) {
        *h = 1;  /* La hauteur a augmente */
        return creerNoeud(usine);
    }

    /* Comparer les identifiants pour trouver la position */
    cmp = strcmp(usine.identifiant, a->usine.identifiant);

    if (cmp < 0) {
        /* Inserer a gauche */
        a->fg = insererAVL(a->fg, usine, h);
        *h = -*h;  /* Inverser car insertion a gauche (eq = droite - gauche) */
    } else if (cmp > 0) {
        /* Inserer a droite */
        a->fd = insererAVL(a->fd, usine, h);
    } else {
        /* Usine deja presente: mettre a jour les valeurs */
        /* Ne mettre a jour capacite_max que si la nouvelle valeur est non nulle */
        if (usine.capacite_max > 0) {
            a->usine.capacite_max = usine.capacite_max;
        }
        a->usine.volume_capte += usine.volume_capte;
        a->usine.volume_traite += usine.volume_traite;
        *h = 0;
        return a;
    }

    /* Mise a jour du facteur d'equilibre et reequilibrage */
    if (*h != 0) {
        a->eq += *h;
        a = equilibrerAVL(a);
        *h = (a->eq == 0) ? 0 : 1;
    }

    return a;
}

/* ========== Recherche ========== */

/* Recherche une usine par son identifiant */
NoeudAVL* rechercherAVL(NoeudAVL *racine, char *identifiant) {
    int cmp;

    if (racine == NULL)
        return NULL;

    cmp = strcmp(identifiant, racine->usine.identifiant);

    if (cmp == 0)
        return racine;
    else if (cmp < 0)
        return rechercherAVL(racine->fg, identifiant);
    else
        return rechercherAVL(racine->fd, identifiant);
}

/* ========== Parcours ========== */

/* 
 * Parcours en ordre inverse (droite, racine, gauche) pour tri alphabetique inverse
 * Mode: 1=max, 2=src, 3=real, 4=all
 */
void parcoursInverseAVL(NoeudAVL *racine, FILE *fichier, int mode) {
    double valMax, valSrc, valReal;
    
    if (racine == NULL)
        return;

    /* Parcours droite d'abord pour ordre inverse */
    parcoursInverseAVL(racine->fd, fichier, mode);

    /* Conversion en millions de m3 (diviser par 1000) */
    valMax = racine->usine.capacite_max / 1000.0;
    valSrc = racine->usine.volume_capte / 1000.0;
    valReal = racine->usine.volume_traite / 1000.0;

    /* Ecrire selon le mode */
    if (mode == 1) {
        fprintf(fichier, "%s;%.6f\n", racine->usine.identifiant, valMax);
    } else if (mode == 2) {
        fprintf(fichier, "%s;%.6f\n", racine->usine.identifiant, valSrc);
    } else if (mode == 3) {
        fprintf(fichier, "%s;%.6f\n", racine->usine.identifiant, valReal);
    } else if (mode == 4) {
        /* Mode bonus: toutes les valeurs */
        fprintf(fichier, "%s;%.6f;%.6f;%.6f\n", 
                racine->usine.identifiant, valReal, valSrc - valReal, valMax - valSrc);
    }

    /* Puis parcours gauche */
    parcoursInverseAVL(racine->fg, fichier, mode);
}

/* ========== Liberation memoire ========== */

/* Libere la memoire de l'arbre */
void libererAVL(NoeudAVL *racine) {
    if (racine == NULL)
        return;
    libererAVL(racine->fg);
    libererAVL(racine->fd);
    free(racine);
}

/* Compte le nombre de noeuds dans l'arbre */
int compterNoeuds(NoeudAVL *racine) {
    if (racine == NULL)
        return 0;
    return 1 + compterNoeuds(racine->fg) + compterNoeuds(racine->fd);
}
