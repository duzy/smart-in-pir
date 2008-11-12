
#include <iostream>

extern void foo();
extern void bar();

int main(int argc, char**argv)
{
  foo();
  bar();
  std::cout<<std::endl;
  return 0;
}
