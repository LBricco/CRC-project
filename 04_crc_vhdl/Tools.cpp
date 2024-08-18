#include <iostream>
#include <fstream>
#include <cstring>
#include <string>
#include <vector>
#include <algorithm>

using namespace std;

#include "Tools.hpp"
#include "Converter.hpp"

// Costruttore
Tools::Tools(string p, int d, string c)
    : poly{p}, deg{d}, crc{c}
{
    vector_message.clear();
    vector_crc.clear();
}

// Distruttore
Tools::~Tools() {}

// Imposta il polinomio generatore di CRC
// @param generator: polinomio generatore (11021 CRC-16-CCITT)
// @param degree: grado polinomio generatore (16 per  CRC-16-CCITT)
// @param init_value: valore di inizializzazione del LFSR (0 per XMODEM)
void Tools::set_crc(string generator, int degree, int init_value)
{
    poly = generator;
    deg = degree;
    init = init_value;

    // individuo i coefficienti del polinomio generatore per capire quando usare l'xor
    coefficients.clear();
    for (int i = 0; i < generator.length(); i++)
    {
        if (generator.substr(i, 1) == "1" && i != 0 && i != generator.length() - 1)
            coefficients.push_back(i - 1);
    }
}

// Calcola il CRC di una parola di 16 bit e la scrive su file
// @param message: messaggio di cui calcolare il CRC in formato binario
void Tools::calc_crc(string message, ofstream &outFile)
{
    Converter C;
    vector_message.clear();
    vector_crc.clear();
    vector<int> old_crc;

    // inserisco il crc nel vettore
    for (int i = 0; i < deg; i++)
    {
        vector_crc.push_back(init);
    }

    message += "0000000000000000";

    // inserisco il messaggio nel vettore
    for (int i = 0; i < message.length(); i++)
    {
        vector_message.push_back(stoi(message.substr(i, 1)));
    }

    // calcolo il CRC usando la stessa tecnica implementata a livello circuitale
    for (int i = 0; i < message.length(); i++)
    {
        old_crc = vector_crc;
        int msg = vector_message.front();             // ingresso LFSR = MSB messaggio
        vector_message.erase(vector_message.begin()); // rimuovo MSB dal messaggio

        for (int j = deg - 1; j >= 0; j--)
        {
            if (j == deg - 1)
                vector_crc[j] = msg ^ old_crc[0];
            else if (find(coefficients.begin(), coefficients.end(), j) != coefficients.end())
                vector_crc[j] = old_crc[j + 1] ^ old_crc[0];
            else
                vector_crc[j] = old_crc[j + 1];
        }
    }

    for (int i = 0; i < deg; i++)
    {
        outFile << vector_crc[i];
    }
    outFile << endl;
}