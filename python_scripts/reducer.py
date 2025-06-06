#!/usr/bin/env python3
import sys


def reducer():
    """
    Reducer pour WordCount en Python
    Lit depuis stdin et écrit vers stdout
    """

    current_word = None
    current_count = 0

    for line in sys.stdin:
        line = line.strip()

        # Parser la ligne (word\tcount)
        try:
            word, count = line.split('\t')
            count = int(count)
        except ValueError:
            # Ignorer les lignes malformées
            continue

        # Si c'est le même mot, additionner
        if current_word == word:
            current_count += count
        else:
            # Nouveau mot, émettre le résultat précédent
            if current_word is not None:
                print(f"{current_word}\t{current_count}")

            current_word = word
            current_count = count

    # Émettre le dernier mot
    if current_word is not None:
        print(f"{current_word}\t{current_count}")


if __name__ == "__main__":
    reducer()