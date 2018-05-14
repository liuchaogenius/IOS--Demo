SDK=$compileEnv
# local run example:SDK=iphoneos5.0
XCODE_PATH=$XCODE_PATH$compileEnv
# local run example:XCODE_PATH=xcodebuild

# warning: Please create a target dailybuildipa, with signing set to com.tencent.*,
# This uses to match the enterprise certificates
$XCODE_PATH -target dailybuildipa -configuration DailyBuild clean -sdk $SDK
if [ -e  build/DailyBuild-iphoneos/*.ipa ] ;then
cd build/DailyBuild-iphoneos;
cd ..
rm -r *;
cd ..;
fi

if [ -e  result ] ;then
rm -r result;
fi
mkdir result;
if [ -e  result/*.ipa ] ;then
rm ./result/*.ipa;
fi

$XCODE_PATH -target dailybuildipa -configuration DailyBuild -sdk $SDK
if ! [ $? = 0 ] ;then
exit 1
fi
cp build/DailyBuild-iphoneos/*.ipa result/${BaseLine}_r${SVN_REVISION}.ipa