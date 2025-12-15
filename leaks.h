/* ========================================
   leaks.h - Calcul des fuites
   ======================================== */

#ifndef LEAKS_H
#define LEAKS_H

// Structure pour l'arbre de distribution
typedef struct TreeNode {
    char *identifier;           // Identifiant du nœud
    double volume;              // Volume d'eau qui transite
    double leak_percent;        // Pourcentage de fuite
    struct TreeNode *children;  // Premier enfant
    struct TreeNode *next;      // Frère suivant (liste chaînée)
} TreeNode;

// Structure pour l'AVL de recherche rapide des nœuds
typedef struct SearchNode {
    char *identifier;
    TreeNode *node_ptr;         // Pointeur vers le nœud dans l'arbre
    int height;
    struct SearchNode *left;
    struct SearchNode *right;
} SearchNode;

// Fonctions principales
int process_leaks(const char *input_file, const char *facility_id, const char *output_file);

// Fonctions de l'arbre de distribution
TreeNode* create_tree_node(const char *identifier);
void free_tree(TreeNode *root);

// Fonctions de l'AVL de recherche
SearchNode* create_search_node(const char *identifier, TreeNode *node_ptr);
SearchNode* insert_search(SearchNode *node, const char *identifier, TreeNode *node_ptr);
TreeNode* find_node(SearchNode *root, const char *identifier);
void free_search_avl(SearchNode *root);
int get_search_height(SearchNode *node);
int get_search_balance(SearchNode *node);
SearchNode* rotate_search_right(SearchNode *y);
SearchNode* rotate_search_left(SearchNode *x);

// Calcul des fuites
double calculate_leaks(TreeNode *root, double incoming_volume);

#endif
