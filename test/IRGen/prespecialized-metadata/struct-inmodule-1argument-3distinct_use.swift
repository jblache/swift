// RUN: %swift -target %module-target-future -emit-ir -prespecialize-generic-metadata %s | %FileCheck %s

// CHECK: @"$s4main5ValueVySSGMf" = internal constant <{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }> <{ i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVWV", i32 0, i32 0), i64 512, %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*), %swift.type* @"$sSSN", i32 0, [4 x i8] zeroinitializer, i64 3 }>, align 8
// CHECK: @"$s4main5ValueVySdGMf" = internal constant <{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }> <{ i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVWV", i32 0, i32 0), i64 512, %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*), %swift.type* @"$sSdN", i32 0, [4 x i8] zeroinitializer, i64 3 }>, align 8
// CHECK: @"$s4main5ValueVySiGMf" = internal constant <{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }> <{ i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVWV", i32 0, i32 0), i64 512, %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*), %swift.type* @"$sSiN", i32 0, [4 x i8] zeroinitializer, i64 3 }>, align 8
struct Value<First> {
  let first: First
}

@inline(never)
func consume<T>(_ t: T) {
  withExtendedLifetime(t) { t in
  }
}

// CHECK: define hidden swiftcc void @"$s4main4doityyF"() #{{[0-9]+}} {
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySdGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySSGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK: }
func doit() {
  consume( Value(first: 13) )
  consume( Value(first: 13.0) )
  consume( Value(first: "13") )
}
doit()

// CHECK: ; Function Attrs: noinline nounwind readnone
// CHECK: define hidden swiftcc %swift.metadata_response @"$s4main5ValueVMa"(i64, %swift.type*) #{{[0-9]+}} {
// CHECK: entry:
// CHECK:   [[ERASED_TYPE:%[0-9]+]] = bitcast %swift.type* %1 to i8*
// CHECK:   br label %[[TYPE_COMPARISON_1:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_1]]:
// CHECK:   [[EQUAL_TYPE_1:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSiN" to i8*), [[ERASED_TYPE]]
// CHECK:   [[EQUAL_TYPES_1:%[0-9]+]] = and i1 true, [[EQUAL_TYPE_1]]
// CHECK:   br i1 [[EQUAL_TYPES_1]], label %[[EXIT_PRESPECIALIZED_1:[0-9]+]], label %[[TYPE_COMPARISON_2:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_2]]:
// CHECK:   [[EQUAL_TYPE_2:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSdN" to i8*), [[ERASED_TYPE]]
// CHECK:   [[EQUAL_TYPES_2:%[0-9]+]] = and i1 true, [[EQUAL_TYPE_2]]
// CHECK:   br i1 [[EQUAL_TYPES_2]], label %[[EXIT_PRESPECIALIZED_2:[0-9]+]], label %[[TYPE_COMPARISON_3:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_3]]:
// CHECK:   [[EQUAL_TYPE_3:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSSN" to i8*), [[ERASED_TYPE]]
// CHECK:   [[EQUAL_TYPES_3:%[0-9]+]] = and i1 true, [[EQUAL_TYPE_3]]
// CHECK:   br i1 [[EQUAL_TYPES_3]], label %[[EXIT_PRESPECIALIZED_3:[0-9]+]], label %[[EXIT_NORMAL:[0-9]+]]
// CHECK: [[EXIT_PRESPECIALIZED_1]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1), i64 0 }
// CHECK: [[EXIT_PRESPECIALIZED_2]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySdGMf" to %swift.full_type*), i32 0, i32 1), i64 0 }
// CHECK: [[EXIT_PRESPECIALIZED_3]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, i64, %swift.type_descriptor*, %swift.type*, i32, [4 x i8], i64 }>* @"$s4main5ValueVySSGMf" to %swift.full_type*), i32 0, i32 1), i64 0 }
// CHECK: [[EXIT_NORMAL]]:
// CHECK:   {{%[0-9]+}} = call swiftcc %swift.metadata_response @__swift_instantiateGenericMetadata(i64 %0, i8* [[ERASED_TYPE]], i8* undef, i8* undef, %swift.type_descriptor* bitcast (<{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i16, i16, i16, i16, i8, i8, i8, i8 }>* @"$s4main5ValueVMn" to %swift.type_descriptor*)) #{{[0-9]+}}
// CHECK:   ret %swift.metadata_response {{%[0-9]+}}
// CHECK: }
