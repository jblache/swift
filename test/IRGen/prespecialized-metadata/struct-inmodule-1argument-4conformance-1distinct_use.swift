// RUN: %swift -target %module-target-future -emit-ir -prespecialize-generic-metadata %s | %FileCheck %s

// CHECK: @"$sytN" = external global %swift.full_type
// CHECK: @"$s4main5ValueVySiGMf" = internal constant <{ i8**, i64, %swift.type_descriptor*, %swift.type*, i8**, i8**, i8**, i8**, i32, [4 x i8], i64 }> <{ i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVWV", i32 0, i32 0), i64 512, %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*), %swift.type* @"$sSiN", i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1PAAWP", i32 0, i32 0), i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1QAAWP", i32 0, i32 0), i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1RAAWP", i32 0, i32 0), i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1SAAWP", i32 0, i32 0), i32 0, [4 x i8] zeroinitializer, i64 3 }>, align 8
protocol P {}
protocol Q {}
protocol R {}
protocol S {}
extension Int : P {}
extension Int : Q {}
extension Int : R {}
extension Int : S {}
struct Value<First : P & Q & R & S> {
  let first: First
}

@inline(never)
func consume<T>(_ t: T) {
  withExtendedLifetime(t) { t in
  }
}

// CHECK: define hidden swiftcc void @"$s4main4doityyF"() #{{[0-9]+}} {
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i8**, i8**, i8**, i8**, i32, [4 x i8], i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK: }
func doit() {
  consume( Value(first: 13) )
}
doit()

// CHECK: ; Function Attrs: noinline nounwind
// CHECK: define hidden swiftcc %swift.metadata_response @"$s4main5ValueVMa"(i64, i8**) #{{[0-9]+}} {
// CHECK: entry:
// CHECK:   [[ERASED_ARGUMENT_BUFFER:%[0-9]+]] = bitcast i8** %1 to i8*
// CHECK:   br label %[[TYPE_COMPARISON_1:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_1]]:
// CHECK:   [[ERASED_TYPE_ADDRESS:%[0-9]+]] = getelementptr i8*, i8** %1, i64 0
// CHECK:   %"load argument at index 0 from buffer" = load i8*, i8** [[ERASED_TYPE_ADDRESS]]
// CHECK:   [[EQUAL_TYPE:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSiN" to i8*), %"load argument at index 0 from buffer"
// CHECK:   [[EQUAL_TYPES:%[0-9]+]] = and i1 true, [[EQUAL_TYPE]]
// CHECK:   br i1 [[EQUAL_TYPES]], label %[[EXIT_PRESPECIALIZED:[0-9]+]], label %[[EXIT_NORMAL:[0-9]+]]
// CHECK: [[EXIT_PRESPECIALIZED]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i8**, i8**, i8**, i8**, i32, [4 x i8], i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1), i64 0 }
// CHECK: [[EXIT_NORMAL]]:
// CHECK:   {{%[0-9]+}} = call swiftcc %swift.metadata_response @swift_getGenericMetadata(i64 %0, i8* [[ERASED_ARGUMENT_BUFFER]], %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*)) #{{[0-9]+}}
// CHECK:   ret %swift.metadata_response {{%[0-9]+}}
// CHECK: }
