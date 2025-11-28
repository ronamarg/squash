from ml_models.code_corruptor.revertV3 import RevertV3

code = """def f(n):
 s=0
 for i in range(1,n+1):
  s+=i
 return s
"""
rv=RevertV3(model_path='ml_models/code_corruptor/code_corruptor_model_final/final_model', device='cuda')
out=rv.corrupt(code)
print('--- ORIGINAL ---')
print(code)
print('--- CORRUPTED ---')
print(out)
print('CHANGED:', out.strip()!=code.strip())
