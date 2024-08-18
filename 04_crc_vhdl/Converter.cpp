#include <iostream>
#include <fstream> // per il file processing
#include <string>  // per creazione e manipolazione stringhe
#include <cstring> // per manipolazione di stringhe C-like
#include <cmath>   // per l'elevazione a potenza con pow(a,b)

#include "Converter.hpp"

using namespace std;

// Costruttore
Converter::Converter(int n, int r)
    : number{n}, result{} {}

// Distruttore
Converter::~Converter() {}

// Converte un numero da intero a binario (con parallelismo a n bit) e scrive il risultato in un file
void Converter::intToBin(string conv_number, unsigned int n, ofstream &outFile)
{
    int digit;                  // singola cifra del numero da convertire
    number = stoi(conv_number); // numero (intero) da convertire

    // Sfruttiamo l'overloading dell'operatore >> (shift right)
    // Ad ogni iterazione shiftiamo number a dx di i posizioni (ovvero calcoliamo number % 2^i) e mettiamo il risultato in bitwise and con 1
    for (int i = n - 1; i >= 0; i--)
    {
        digit = (number >> (i)) & 1;
        outFile << digit;
    }
}

// Converte un numero da binario a intero
int Converter::binToInt(string conv_number)
{
    result = 0;
    int bit_number = conv_number.length();
    for (int i = 0; i < bit_number; i++)
    {
        string bit = conv_number.substr(i, 1);          // estraggo l'i-esimo bit
        int bit_int = stoi(bit);                        // trasformo il bit in un numero intero
        result += pow(2, bit_number - 1 - i) * bit_int; // incremento il risultato
    }
    return result;
}