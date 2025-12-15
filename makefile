# ========================================
# Makefile - Compilation du projet
# ========================================

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
LDFLAGS = -lm

TARGET = wildwater
OBJS = main.o avl.o histo.o leaks.o

# Cible par défaut
all: $(TARGET)

# Compilation de l'exécutable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

# Compilation des fichiers objets
main.o: main.c avl.h histo.h leaks.h
	$(CC) $(CFLAGS) -c main.c

avl.o: avl.c avl.h
	$(CC) $(CFLAGS) -c avl.c

histo.o: histo.c histo.h avl.h
	$(CC) $(CFLAGS) -c histo.c

leaks.o: leaks.c leaks.h
	$(CC) $(CFLAGS) -c leaks.c

# Nettoyage
clean:
	rm -f $(OBJS) $(TARGET)
	rm -f *.dat *.tmp *.png

# Nettoyage complet (inclut les fichiers générés)
mrproper: clean
	rm -f vol_*.dat leaks.dat
	rm -f filtered_*.tmp
	rm -f *.png

.PHONY: all clean mrproper
