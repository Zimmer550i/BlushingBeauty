import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            SizedBox(height: 24,),
                Row(
                  children: [
                    InkWell(
                      onTap: (){
                        Get.back();
                      },
                        child: Icon(Icons.arrow_back, color: AppColors.textColor,)),
                    SizedBox(width: 12,),
                    Text("Notifications",
                      style: TextStyle(color: AppColors.textColor,
                          fontSize: 24, fontWeight: FontWeight.w600),),
                    Spacer(),
                    InkWell(
                      onTap: (){
                        Get.back();
                      },
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                        ),
                        child: Icon(Icons.close),
                      ),
                    ),
                    SizedBox(width: 12),

                  ],


            ),

            Expanded(
              child: ListView.separated(
                  itemBuilder: (context, index){
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7FBF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage("assets/images/dummy.jpg"),
                                  fit: BoxFit.cover,
                                ),
                              )
                          ),
                          SizedBox(width: 12,),
                          Expanded(
                            child: Text("Wasi Nkhaki Want’s to talk with you!",
                              style: TextStyle(color: AppColors.textColor,
                                  fontSize: 16, fontWeight: FontWeight.w600),),
                          ),
                          SizedBox(width: 12,),
                          Text("10:00 PM",
                            style: TextStyle(
                              color: Color(0xFF807E7E),
                              fontSize: 14, fontWeight: FontWeight.w400,
                            ),)


                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 16,),
                  itemCount: 5),
            )

          ],
        ),
      ),
    );
  }
}
