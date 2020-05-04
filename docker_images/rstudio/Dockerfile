FROM rocker/verse:3.6.0


# USER root
RUN git config --global user.email ccdelgado@u-bordeaux.fr && git config --global user.name christian
RUN install2.r --error \
    --deps TRUE -n 4 \
    philentropy stringr miceadds 
RUN install2.r --error \
    --deps TRUE -n 4 ggsci car
RUN install2.r --error \
    --deps TRUE -n 4 \
    stargazer rms tikzDevice
