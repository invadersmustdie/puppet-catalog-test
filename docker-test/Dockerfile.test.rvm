FROM adgud2/ruby-rvm

ARG RUBY_VERSION
ENV PATH $PATH:/usr/local/rvm/bin

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN /bin/bash rvm use $RUBY_VERSION --install --binary --fuzzy 
RUN /bin/bash -l -c "rvm use --default $RUBY_VERSION"

ENTRYPOINT ["/bin/bash", "-c"]
