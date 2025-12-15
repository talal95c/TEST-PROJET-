/* ========================================
   avl.h - Structure et fonctions AVL
   ======================================== */

#ifndef AVL_H
#define AVL_H

// Structure d'un nœud AVL pour les histogrammes
typedef struct AVLNode {
    char *identifier;           // Identifiant de l'usine
    double volume;              // Volume (selon le mode: max, src, ou real)
    int height;                 // Hauteur du nœud pour l'équilibrage
    struct AVLNode *left;
    struct AVLNode *right;
} AVLNode;

// Fonctions de l'AVL
AVLNode* create_node(const char *identifier, double volume);
int get_height(AVLNode *node);
int get_balance(AVLNode *node);
AVLNode* rotate_right(AVLNode *y);
AVLNode* rotate_left(AVLNode *x);
AVLNode* insert_avl(AVLNode *node, const char *identifier, double volume);
void free_avl(AVLNode *root);
void write_avl_inorder(AVLNode *root, FILE *output);

#endif
