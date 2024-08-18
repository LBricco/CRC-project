#ifndef TOOLS_H
#define TOOLS_H

using namespace std;

class Tools
{
public:
    explicit Tools(string = "", int = 0, string = "0000000000000000"); // costruttore
    ~Tools();                                                          // distruttore

    void set_crc(string generator, int degree, int init_value);
    void calc_crc(string message, ofstream &outFile);

private:
    string poly;
    int deg;
    vector<int> coefficients;
    int init;
    vector<int> vector_message;
    vector<int> vector_crc;
    string crc;
};

#endif