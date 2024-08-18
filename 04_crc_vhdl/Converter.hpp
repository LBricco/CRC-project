#ifndef CONVERTER_H // se il simbolo CONVERTER_H non è definito
#define CONVERTER_H // definisci il simbolo CONVERTER_H

#include <string>
using namespace std;

class Converter
{
public:
    explicit Converter(int = 0, int = 0); // costruttore
    ~Converter();                         // distruttore

    // Metodi pubblici
    void intToBin(string conv_number, unsigned int n, ofstream &outFile);
    int binToInt(string conv_number);

private:
    int number;
    int result;
};

#endif