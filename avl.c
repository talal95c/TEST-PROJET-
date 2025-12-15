/* ========================================
   avl.c - Implémentation de l'AVL
   ======================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "avl.h"

// Créer un nouveau nœud
AVLNode* create_node(const char *identifier, double volume) {
    AVLNode *node = (AVLNode*)malloc(sizeof(AVLNode));
    if (node == NULL) {
        return NULL;
    }
    
    node->identifier = (char*)malloc(strlen(identifier) + 1);
    if (node->identifier == NULL) {
        free(node);
        return NULL;
    }
    
    strcpy(node->identifier, identifier);
    node->volume = volume;
    node->height = 1;
    node->left = NULL;
    node->right = NULL;
    
    return node;
}

// Obtenir la hauteur d'un nœud
int get_height(AVLNode *node) {
    if (node == NULL) {
        return 0;
    }
    return node->height;
}

// Calculer le facteur d'équilibre
int get_balance(AVLNode *node) {
    if (node == NULL) {
        return 0;
    }
    return get_height(node->left) - get_height(node->right);
}

// Rotation droite
AVLNode* rotate_right(AVLNode *y) {
    AVLNode *x = y->left;
    AVLNode *T2 = x->right;
    
    x->right = y;
    y->left = T2;
    
    // Mise à jour des hauteurs
    y->height = 1 + (get_height(y->left) > get_height(y->right) ? 
                     get_height(y->left) : get_height(y->right));
    x->height = 1 + (get_height(x->left) > get_height(x->right) ? 
                     get_height(x->left) : get_height(x->right));
    
    return x;
}

// Rotation gauche
AVLNode* rotate_left(AVLNode *x) {
    AVLNode *y = x->right;
    AVLNode *T2 = y->left;
    
    y->left = x;
    x->right = T2;
    
    // Mise à jour des hauteurs
    x->height = 1 + (get_height(x->left) > get_height(x->right) ? 
                     get_height(x->left) : get_height(x->right));
    y->height = 1 + (get_height(y->left) > get_height(y->right) ? 
                     get_height(y->left) : get_height(y->right));
    
    return y;
}

// Insertion dans l'AVL avec équilibrage
AVLNode* insert_avl(AVLNode *node, const char *identifier, double volume) {
    // Insertion classique
    if (node == NULL) {
        return create_node(identifier, volume);
    }
    
    int cmp = strcmp(identifier, node->identifier);
    
    if (cmp < 0) {
        node->left = insert_avl(node->left, identifier, volume);
    } else if (cmp > 0) {
        node->right = insert_avl(node->right, identifier, volume);
    } else {
        // L'identifiant existe déjà, on additionne les volumes
        node->volume += volume;
        return node;
    }
    
    // Mise à jour de la hauteur
    node->height = 1 + (get_height(node->left) > get_height(node->right) ? 
                        get_height(node->left) : get_height(node->right));
    
    // Calcul du facteur d'équilibre
    int balance = get_balance(node);
    
    // Cas de déséquilibre
    
    // Cas gauche-gauche
    if (balance > 1 && strcmp(identifier, node->left->identifier) < 0) {
        return rotate_right(node);
    }
    
    // Cas droite-droite
    if (balance < -1 && strcmp(identifier, node->right->identifier) > 0) {
        return rotate_left(node);
    }
    
    // Cas gauche-droite
    if (balance > 1 && strcmp(identifier, node->left->identifier) > 0) {
        node->left = rotate_left(node->left);
        return rotate_right(node);
    }
    
    // Cas droite-gauche
    if (balance < -1 && strcmp(identifier, node->right->identifier) < 0) {
        node->right = rotate_right(node->right);
        return rotate_left(node);
    }
    
    return node;
}

// Libérer la mémoire de l'AVL
void free_avl(AVLNode *root) {
    if (root == NULL) {
        return;
    }
    
    free_avl(root->left);
    free_avl(root->right);
    free(root->identifier);
    free(root);
}

// Écrire l'AVL dans un fichier (parcours infixe = ordre alphabétique)
void write_avl_inorder(AVLNode *root, FILE *output) {
    if (root == NULL) {
        return;
    }
    
    write_avl_inorder(root->left, output);
    fprintf(output, "%s;%.3f\n", root->identifier, root->volume / 1000.0);
    write_avl_inorder(root->right, output);
}
