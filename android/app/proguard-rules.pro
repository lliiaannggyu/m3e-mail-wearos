# M3E Mail — R8 混淆补充规则
# Flutter Gradle 插件已自动追加：
#   proguard-android-optimize.txt（R8 优化基线）
#   flutter_proguard_rules.pro（Flutter 引擎/插件保底规则，如保留 FlutterPlugin 实现）
#
# 纯 Dart UI（material_3_expressive 组件）不进 dex，无需 keep；
# 此处只保留运行期反射/序列化所需的规则。

# 若后续接入 JSON 序列化库（如 json_serializable / gson），按需在此添加 keep 规则。
# 例如：
# -keep class com.workbuddy.m3e_mail.** extends java.io.Serializable { *; }
