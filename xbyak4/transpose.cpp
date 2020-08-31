#include <cstdio>
#include <x86intrin.h>

double a[] = {0.0, 0.1, 0.2, 0.3};
double b[] = {1.0, 1.1, 1.2, 1.3};
double c[] = {2.0, 2.1, 2.2, 2.3};
double d[] = {3.0, 3.1, 3.2, 3.3};

void transpose(void) {
  __m256d va = _mm256_load_pd(a);
  __m256d vb = _mm256_load_pd(b);
  __m256d vc = _mm256_load_pd(c);
  __m256d vd = _mm256_load_pd(d);
  __m256d tmp0 = _mm256_unpacklo_pd(va, vb);
  __m256d tmp1 = _mm256_unpackhi_pd(va, vb);
  __m256d tmp2 = _mm256_unpacklo_pd(vc, vd);
  __m256d tmp3 = _mm256_unpackhi_pd(vc, vd);
  __m256d r0 = _mm256_permute2f128_pd(tmp0, tmp2, 2 * 16 + 1 * 0);
  __m256d r1 = _mm256_permute2f128_pd(tmp1, tmp3, 2 * 16 + 1 * 0);
  __m256d r2 = _mm256_permute2f128_pd(tmp0, tmp2, 3 * 16 + 1 * 1);
  __m256d r3 = _mm256_permute2f128_pd(tmp1, tmp3, 3 * 16 + 1 * 1);
  _mm256_store_pd(a, r0);
  _mm256_store_pd(b, r1);
  _mm256_store_pd(c, r2);
  _mm256_store_pd(d, r3);
}

void show(void){
  printf("%f %f %f %f\n",a[0],a[1],a[2],a[3]);
  printf("%f %f %f %f\n",b[0],b[1],b[2],b[3]);
  printf("%f %f %f %f\n",c[0],c[1],c[2],c[3]);
  printf("%f %f %f %f\n",d[0],d[1],d[2],d[3]);
  puts("");
}

int main(){
  puts("Before");
  show();
  transpose();
  puts("After");
  show();
}
