#include <iostream>

//extern void foo();
//extern void bar();
#include <foo.hpp>
#include <bar.hpp>

int main(int argc, char** argv)
{
  foo();
  bar();
  std::cout<<std::endl;
  return 0;
}

