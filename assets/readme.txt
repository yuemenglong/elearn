根据输入的图片里的内容，按照NewConcept1/lesson_001.xml的格式生成对应的xml文件，文件名中的编号为对应的课程编号
注意：英文每个句号都要隔开为单独的句子
注意：如果某句话前面有人名，即表示这个说的话，这个人名不需要提取出来
无论英文和中文，只要是句号问好感叹号都是一个句子，例如：
<sentence>
<text>He wasn't dreaming, officer. I was telling him to drive slowly.</text>
<textCn>警官，他思想没有开小差。我刚才正告诉他开慢点。</textCn>
</sentence>
需要拆分成
1. 警官，他思想没有开小差。
2. 我刚才正告诉他开慢点。