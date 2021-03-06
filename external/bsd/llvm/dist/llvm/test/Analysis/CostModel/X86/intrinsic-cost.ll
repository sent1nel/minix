; RUN: opt -S -mtriple=x86_64-apple-darwin -mcpu=core2 -cost-model -analyze < %s | FileCheck %s -check-prefix=CORE2
; RUN: opt -S -mtriple=x86_64-apple-darwin -mcpu=corei7 -cost-model -analyze < %s | FileCheck %s -check-prefix=COREI7

; If SSE4.1 roundps instruction is available it is cheap to lower, otherwise
; it'll be scalarized into calls which are expensive.
define void @test1(float* nocapture %f) nounwind {
vector.ph:
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %0 = getelementptr inbounds float* %f, i64 %index
  %1 = bitcast float* %0 to <4 x float>*
  %wide.load = load <4 x float>* %1, align 4
  %2 = call <4 x float> @llvm.ceil.v4f32(<4 x float> %wide.load)
  store <4 x float> %2, <4 x float>* %1, align 4
  %index.next = add i64 %index, 4
  %3 = icmp eq i64 %index.next, 1024
  br i1 %3, label %for.end, label %vector.body

for.end:                                          ; preds = %vector.body
  ret void

; CORE2: Printing analysis 'Cost Model Analysis' for function 'test1':
; CORE2: Cost Model: Found an estimated cost of 400 for instruction:   %2 = call <4 x float> @llvm.ceil.v4f32(<4 x float> %wide.load)

; COREI7: Printing analysis 'Cost Model Analysis' for function 'test1':
; COREI7: Cost Model: Found an estimated cost of 1 for instruction:   %2 = call <4 x float> @llvm.ceil.v4f32(<4 x float> %wide.load)

}

declare <4 x float> @llvm.ceil.v4f32(<4 x float>)  nounwind readnone

define void @test2(float* nocapture %f) nounwind {
vector.ph:
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %0 = getelementptr inbounds float* %f, i64 %index
  %1 = bitcast float* %0 to <4 x float>*
  %wide.load = load <4 x float>* %1, align 4
  %2 = call <4 x float> @llvm.nearbyint.v4f32(<4 x float> %wide.load)
  store <4 x float> %2, <4 x float>* %1, align 4
  %index.next = add i64 %index, 4
  %3 = icmp eq i64 %index.next, 1024
  br i1 %3, label %for.end, label %vector.body

for.end:                                          ; preds = %vector.body
  ret void

; CORE2: Printing analysis 'Cost Model Analysis' for function 'test2':
; CORE2: Cost Model: Found an estimated cost of 400 for instruction:   %2 = call <4 x float> @llvm.nearbyint.v4f32(<4 x float> %wide.load)

; COREI7: Printing analysis 'Cost Model Analysis' for function 'test2':
; COREI7: Cost Model: Found an estimated cost of 1 for instruction:   %2 = call <4 x float> @llvm.nearbyint.v4f32(<4 x float> %wide.load)

}

declare <4 x float> @llvm.nearbyint.v4f32(<4 x float>)  nounwind readnone
