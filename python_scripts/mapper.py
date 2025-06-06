#!/usr/bin/env python3

import sys
import re


def mapper():
    """
    Mapper pour WordCount en Python
    Lit depuis stdin et écrit vers stdout
    """
    for line in sys.stdin:
        # Nettoyer et diviser la ligne en mots
        line = line.strip().lower()
        # Supprimer la ponctuation et diviser en mots
        words = re.findall(r'[a-zA-Z]+', line)

        for word in words:
            if word:  # Ignorer les mots vides
                # Émettre (mot, 1) - format key\tvalue
                print(f"{word}\t1")


if __name__ == "__main__":
    mapper()
